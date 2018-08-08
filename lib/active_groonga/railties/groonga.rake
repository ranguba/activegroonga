# -*- ruby -*-
#
# Copyright (C) 2010-2013  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

namespace :groonga do
  task :load_config do
    require "active_groonga"
    configurations = Rails.application.config.groonga_configurations
    ActiveGroonga::Base.configurations = configurations
    ActiveGroonga::Base.configure(Rails.env)
    ActiveGroonga::Base.database.ensure_available
  end

  desc "Drops the database."
  task :drop => :load_config do
    database = ActiveGroonga::Base.database
    database.remove if database
    database_path = ActiveGroonga::Base.database_path
    tables_path = Pathname("#{database_path}.tables")
    rm_rf(tables_path) if tables_path.exist?
  end

  desc "Create the database."
  task :create => :load_config do
    ActiveGroonga::Base.database.ensure_available
  end

  migrations_path = Proc.new do
    Rails.root + "db" + "groonga" + "migrate"
  end
  desc "Migrate the database (options: VERSION=x)."
  task :migrate => :environment do
    version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    migrator = ActiveGroonga::Migrator.new(:up, migrations_path.call)
    migrator.migrate(version)
    Rake::Task["groonga:schema:dump"].invoke
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :environment do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    migrator = ActiveGroonga::Migrator.new(:down, migrations_path.call)
    version, migrated_at = migrator.migrated_versions[-step]
    migrator.migrate(version)
    Rake::Task["groonga:schema:dump"].invoke
  end

  namespace :migrate do
    desc 'Rolls the schema back and migrate the schema again.'
    task :redo => :environment do
      if ENV["VERSION"]
        Rake::Task["groonga:migrate:down"].invoke
        Rake::Task["groonga:migrate:up"].invoke
      else
        Rake::Task["groonga:rollback"].invoke
        Rake::Task["groonga:migrate"].invoke
      end
    end

    desc 'Migrate the schema up to the version (options: VERSION=x).'
    task :up => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      migrator = ActiveGroonga::Migrator.new(:up, migrations_path.call)
      migrator.migrate(version)
      Rake::Task["groonga:schema:dump"].invoke
    end

    desc 'Migrate the schema down to the version (options: VERSION=x).'
    task :down => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      migrator = ActiveGroonga::Migrator.new(:down, migrations_path.call)
      migrator.migrate(version)
      Rake::Task["groonga:schema:dump"].invoke
    end

    desc "Display status of migration"
    task :status => [:environment, "groonga:load_config"] do
      schema_table = ActiveGroonga::Migrator.new(:up, migrations_path.call).management_table
      db_list = schema_table.migrated_versions
      db_list.map! { |version| "%.3d" % version }
      file_list = []
      Dir.foreach(migrations_path.call).each do |path|
        if /([0-9]+)_([_a-z0-9]+)\.rb/ =~ path
          status = db_list.delete($1) ? "up" : "down"
          file_list << [status, $1, $2.humanize]
        end
      end
      db_list.map! do |version|
        ["up", version, "********** NO FILE **********"]
      end
      puts "\n"
      puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
      puts "-" * 50
      (db_list + file_list).sort_by {|migration| migration[1]}.each do |migration|
        puts "#{migration[0].center(8)}  #{migration[1].ljust(14)}  #{migration[2]}"
      end
      puts
    end
  end

  namespace :schema do
    schema_name = Proc.new do
      Pathname(ENV['SCHEMA'] || (Rails.root + "db" + "groonga" + "schema.rb"))
    end

    desc "Load the schema."
    task :load => "groonga:load_config" do
      schema = schema_name.call
      if schema.exist?
        load(schema)
      else
        Rake::Task["groonga:migrate"].invoke
      end
    end

    desc "Dump the schema."
    task :dump => "groonga:load_config" do
      schema = schema_name.call
      mkdir_p(schema.dirname.to_s) unless schema.dirname.exist?
      begin
        schema.open("w") do |schema_file|
          ActiveGroonga::Schema.dump(schema_file)
        end
      rescue Exception
        rm_f(schema.to_s)
        raise
      end
    end
  end

  desc('Load the seed data from db/groonga/seeds/#{RAILS_ENV}.grn, ' +
       'db/groonga/seeds/#{RAILS_ENV}.rb, db/groonga/seeds.grn or ' +
       'db/groonga/seeds.rb')
  task :seed => :environment do
    base_dir = Rails.root + "db" + "groonga"
    candidates = [base_dir + "seeds" + "#{Rails.env}.grn",
                  base_dir + "seeds" + "#{Rails.env}.rb",
                  base_dir + "seeds.grn",
                  base_dir + "seeds.rb"]
    seed_file_path = candidates.find(&:exist?)
    extension = nil
    extension = seed_file_path.extname if seed_file_path
    case extension
    when /\A\.grn\z/i
      ActiveGroonga::Base.database.ensure_available
      context = ActiveGroonga::Base.context
      seed_file_path.open do |seed_file|
        seed_file.each_line do |line|
          puts("> #{line}")
          context.send(line)
          id, result = context.receive
          puts(result) unless result.empty?
        end
      end
    when /\A\.rb\z/i
      load(seed_file_path)
    when nil
      candidate_paths = candidates.collect(&:to_s)
      raise "seed file doesn't exist. candidates: #{candidate_paths.inspect}"
    else
      raise "unsupported seed file type: <#{seed_file_path}>"
    end
  end

  desc "Create the database and load the schema."
  task :setup => [:create, "groonga:schema:load", :seed]

  task :reset => [:drop, :setup]

  namespace :test do
    desc "Set Rails.env = 'test'"
    task :env do
      ENV["RAILS_ENV"] = "test"
      Rails.env = "test"
    end

    desc "Prepare groonga database for testing"
    task :prepare => [:env,
                      "groonga:drop",
                      "groonga:create",
                      "groonga:schema:load"]
  end
end

case Rails.configuration.generators.options[:rails][:test_framework]
when :rspec
  rspec_task_names = ["spec"]
  rspec_sub_task_names = [:requests, :models, :controllers, :views, :helpers,
                          :mailers, :lib, :routing, :rcov]
  rspec_task_names += rspec_sub_task_names.collect {|name| "spec:#{name}"}
  rspec_task_names.each do |task_name|
    task task_name => "groonga:test:prepare"
  end
else
  task "test:prepare" => "groonga:test:prepare"
end
