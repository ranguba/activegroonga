# -*- ruby -*-
#
# Copyright (C) 2010  Kouhei Sutou <kou@clear-code.com>
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
  task :load_config => :rails_env do
    require "active_groonga"
    configurations = Rails.application.config.groonga_configurations
    ActiveGroonga::Base.configurations = configurations
    ActiveGroonga::Base.configure(Rails.env)
  end

  desc "Drops the database."
  task :drop => :load_config do
    database = ActiveGroonga::Base.database
    database.remove if database
    database_path = ActiveGroonga::Base.database_path
    tables_path = Pathname("#{database_path}.talbes")
    rm_rf(tables_path) if tables_path.exist?
  end

  desc "Create the database."
  task :create => :load_config do
    ActiveGroonga::Base.database.ensure_available
  end

  desc "Migrate the database (options: VERSION=x, VERBOSE=false)."
  task :migrate => :environment do
    migrations_path = Rails.root + "db" + "groonga" + "migrate"
    migrator = ActiveGroonga::Migrator.new(:up, migrations_path)
    migrator.migrate
    Rake::Task["groonga:schema:dump"].invoke
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
  task :seed => :load_config do
    base_dir = Rails.root + "db" + "groonga"
    candidates = [base_dir + "seeds" + "#{Rails.env}.grn",
                  base_dir + "seeds" + "#{Rails.env}.rb",
                  base_dir + "seeds.grn",
                  base_dir + "seeds.rb"]
    seed_file_path = candidates.find(&:exist?)
    break unless seed_file_path
    case seed_file_path.extname
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
    else
      raise "unsupported seed file type: <#{seed_file_path}>"
    end
  end

  desc "Create the database and load the schema."
  task :setup => [:create, "groonga:schema:load", :seed]

  task :reset => [:drop, :setup]

  namespace :test do
    desc "Prepare groonga database for testing"
    task :prepare => [:purge] do
      ActiveGroonga::Base.configure("test")
      Rake::Task["groonga:drop"].invoke
      Rake::Task["groonga:create"].invoke
      Rake::Task["groonga:schema:load"].invoke
    end
  end
end

task "test:prepare" => "groonga:test:prepare"
