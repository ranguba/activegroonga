# -*- ruby -*-

Rake::Task['db:test:prepare'].clear

namespace :groonga do
  task :load_config => :rails_env do
    require 'active_groonga'
    ActiveGroonga::Base.configurations = Rails::Configuration.new.groonga_configuration
  end

  desc "Migrate the database through scripts in db/groonga/migrate and update db/groonga/schema.rb by invoking groonga:schema:dump. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  task :migrate => :environment do
    ActiveGroonga::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveGroonga::Migrator.migrate("db/groonga/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["groonga:schema:dump"].invoke if ActiveGroonga::Base.schema_format == :ruby
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
end
