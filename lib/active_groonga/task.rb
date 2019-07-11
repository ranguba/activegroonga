# Copyright (C) 2010-2018  Kouhei Sutou <kou@clear-code.com>
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

module ActiveGroonga
  class Task
    include Rake::DSL

    def initialize
      @migrations_path = Rails.root + "db" + "groonga" + "migrate"
      schema_path = ENV["SCHEMA"]
      schema_path ||= Rails.root + "db" + "groonga" + "schema.rb"
      @schema_path = Pathname.new(schema_path)
    end

    def define
      namespace :groonga do
        define_load_config_task
        define_drop_task
        define_create_task
        define_migrate_task
        define_rollback_task
        define_migrate_tasks
        define_schema_tasks
        define_seed_task
        define_setup_task
        define_reset_task
        define_test_tasks
      end
      adjust_test_tasks
    end

    private
    def define_load_config_task
      task :load_config do
        require "active_groonga"
        configurations = Rails.application.config.groonga_configurations
        Base.configurations = configurations
        Base.configure(Rails.env)
      end
    end

    def define_drop_task
      desc "Drops the database."
      task :drop => :load_config do
        database = Base.database
        database.remove if database
        database_path = Base.database_path
        tables_path = Pathname.new("#{database_path}.tables")
        rm_rf(tables_path) if tables_path.exist?
      end
    end

    def define_create_task
      desc "Create the database."
      task :create => :load_config do
        Base.database.ensure_available
      end
    end

    def define_migrate_task
      desc "Migrate the database (options: VERSION=x)."
      task :migrate => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        migrator = Migrator.new(:up, @migrations_path)
        migrator.migrate(version)
        Rake::Task["groonga:schema:dump"].invoke
      end
    end

    def define_rollback_task
      desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
      task :rollback => :environment do
        step = ENV['STEP'] ? ENV['STEP'].to_i : 1
        migrator = Migrator.new(:down, @migrations_path)
        version, migrated_at = migrator.migrated_versions[-step]
        migrator.migrate(version)
        Rake::Task["groonga:schema:dump"].invoke
      end
    end

    def define_migrate_tasks
      namespace :migrate do
        define_migrate_redo_task
        define_migrate_up_task
        define_migrate_down_task
        define_migrate_status_task
      end
    end

    def define_migrate_redo_task
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
    end

    def define_migrate_up_task
      desc 'Migrate the schema up to the version (options: VERSION=x).'
      task :up => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        migrator = Migrator.new(:up, @migrations_path)
        migrator.migrate(version)
        Rake::Task["groonga:schema:dump"].invoke
      end
    end

    def define_migrate_down_task
      desc 'Migrate the schema down to the version (options: VERSION=x).'
      task :down => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        migrator = Migrator.new(:down, @migrations_path)
        migrator.migrate(version)
        Rake::Task["groonga:schema:dump"].invoke
      end
    end

    def define_migrate_status_task
      desc "Display status of migration"
      task :status => [:environment, "groonga:load_config"] do
        schema_table = Migrator.new(:up, @migrations_path).management_table
        db_list = schema_table.migrated_versions
        db_list.collect! {|version| "%.3d" % version}
        file_list = []
        Dir.foreach(@migrations_path).each do |path|
          if /([0-9]+)_([_a-z0-9]+)\.rb/ =~ path
            status = db_list.delete($1) ? "up" : "down"
            file_list << [status, $1, $2.humanize]
          end
        end
        db_list.collect! do |version|
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

    def define_schema_tasks
      namespace :schema do
        define_schema_load_task
        define_schema_dump_task
      end
    end

    def define_schema_load_task
      desc "Load the schema."
      task :load => "groonga:load_config" do
        if @schema_path.exist?
          load(@schema_path)
        else
          Rake::Task["groonga:migrate"].invoke
        end
      end
    end

    def define_schema_dump_task
      desc "Dump the schema."
      task :dump => "groonga:load_config" do
        mkdir_p(@schema_path.dirname.to_s) unless @schema_path.dirname.exist?
        begin
          @schema_path.open("w") do |schema_file|
            ActiveGroonga::Schema.dump(schema_file)
          end
        rescue Exception
          rm_f(@schema_path.to_s)
          raise
        end
      end
    end

    def define_seed_task
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
          Base.database.ensure_available
          context = Base.context
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
    end

    def define_setup_task
      desc "Create the database and load the schema."
      task :setup => [:create, "groonga:schema:load", :seed]
    end

    def define_reset_task
      task :reset => [:drop, :setup]
    end

    def define_test_tasks
      namespace :test do
        define_test_env_task
        define_test_prepare_task
      end
    end

    def define_test_env_task
      desc "Set Rails.env = 'test'"
      task :env do
        ENV["RAILS_ENV"] = "test"
        Rails.env = "test"
      end
    end

    def define_test_prepare_task
      desc "Prepare groonga database for testing"
      task :prepare => [:env,
                        "groonga:drop",
                        "groonga:create",
                        "groonga:schema:load"]
    end

    def adjust_test_tasks
      case Rails.configuration.generators.options[:rails][:test_framework]
      when :rspec
        rspec_task_names = ["spec"]
        rspec_sub_task_names = [
          :requests,
          :models,
          :controllers,
          :views,
          :helpers,
          :mailers,
          :lib,
          :routing,
          :rcov,
        ]
        rspec_task_names += rspec_sub_task_names.collect {|name| "spec:#{name}"}
        rspec_task_names.each do |task_name|
          task task_name => "groonga:test:prepare"
        end
      else
        task "test:prepare" => "groonga:test:prepare"
      end
    end
  end
end
