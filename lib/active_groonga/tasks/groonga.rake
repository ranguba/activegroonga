# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
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

# This library includes ActiveRecord based codes temporary.
# Here is their copyright and license:
#
#   Copyright (c) 2004-2009 David Heinemeier Hansson
#
#   Permission is hereby granted, free of charge, to any person obtaining
#   a copy of this software and associated documentation files (the
#   "Software"), to deal in the Software without restriction, including
#   without limitation the rights to use, copy, modify, merge, publish,
#   distribute, sublicense, and/or sell copies of the Software, and to
#   permit persons to whom the Software is furnished to do so, subject to
#   the following conditions:
#
#   The above copyright notice and this permission notice shall be
#   included in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#   OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#   WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

namespace :groonga do
  task :load_config => :rails_env do
    require 'active_groonga'
    ActiveGroonga::Base.configurations = Rails::Configuration.new.groonga_configuration
  end

  desc "Migrate the database through scripts in db/groonga/migrate and update db/groonga/schema.rb by invoking groonga:schema:dump. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  task :migrate => :environment do
    ActiveGroonga::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveGroonga::Migrator.migrate("db/groonga/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["groonga:schema:dump"].invoke
  end

  namespace :migrate do
    desc  'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
    task :redo => :environment do
      if ENV["VERSION"]
        Rake::Task["groonga:migrate:down"].invoke
        Rake::Task["groonga:migrate:up"].invoke
      else
        Rake::Task["groonga:rollback"].invoke
        Rake::Task["groonga:migrate"].invoke
      end
    end

    desc 'Resets your database using your migrations for the current environment'
    task :reset => ["groonga:drop", "groonga:create", "groonga:migrate"]

    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      ActiveGroonga::Migrator.run(:up, "db/groonga/migrate/", version)
      Rake::Task["groonga:schema:dump"].invoke
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      ActiveGroonga::Migrator.run(:down, "db/groonga/migrate/", version)
      Rake::Task["db:schema:dump"].invoke
    end
  end

  desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
  task :rollback => :environment do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveGroonga::Migrator.rollback('db/groonga/migrate/', step)
    Rake::Task["groonga:schema:dump"].invoke
  end

  desc 'Drops and recreates the database from db/groonga/schema.rb for the current environment.'
  task :reset => ['groonga:drop', 'groonga:create', 'groonga:schema:load']

  desc "Retrieves the current schema version number"
  task :version => :environment do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end

  desc "Raises an error if there are pending migrations"
  task :abort_if_pending_migrations => :environment do
    if defined? ActiveGroonga
      pending_migrations = ActiveGroonga::Migrator.new(:up, 'db/groonga/migrate').pending_migrations

      if pending_migrations.any?
        puts "You have #{pending_migrations.size} pending migrations:"
        pending_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %{Run "rake groonga:migrate" to update your database then try again.}
      end
    end
  end

  namespace :schema do
    desc "Create a db/groonga/schema.rb file"
    task :dump => :environment do
      require 'active_groonga/schema_dumper'
      File.open(ENV['SCHEMA'] || "#{RAILS_ROOT}/db/groonga/schema.rb", "w") do |file|
        ActiveGroonga::SchemaDumper.dump(file)
      end
      Rake::Task["groonga:schema:dump"].reenable
    end

    desc "Load a schema.rb file into the database"
    task :load => :environment do
      file = ENV['SCHEMA'] || "#{RAILS_ROOT}/db/groonga/schema.rb"
      load(file)
    end
  end

  namespace :test do
    desc "Recreate the test database from the current schema.rb"
    task :load => 'groonga:test:purge' do
      ActiveGroonga::Base.setup_database(:test)
      ActiveGroonga::Migration.verbose = false
      Rake::Task["groonga:schema:load"].invoke
    end

    desc "Recreate the test database from the current environment's database schema"
    task :clone => %w(groonga:schema:dump groonga:test:load)

    desc "Recreate the test databases from the development structure"
    task :clone_structure => ["groonga:schema:dump", "groonga:test:purge"] do
      RAILS_ENV.replace("test")
      Rake::Task["groonga:schema:load"].invoke
    end

    desc "Empty the test database"
    task :purge => :environment do
      ActiveGroonga::Base.setup_database(:test)
      ActiveGroonga::Base.database.remove
      rm_rf(ActiveGroonga::Base.database_directory)
      # FIXME: groonga isn't fully implemented remove for database.
    end

    desc 'Check for pending migrations and load the test schema'
    task :prepare => 'groonga:abort_if_pending_migrations' do
      if defined?(ActiveGroonga) && !ActiveGroonga::Base.configurations.blank?
        Rake::Task["groonga:test:load"].invoke
      end
    end
  end
end
