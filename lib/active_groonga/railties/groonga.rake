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
  end

  desc "Create the database."
  task :create => :load_config do
    ActiveGroonga::Base.database
  end

  desc "Migrate the database (options: VERSION=x, VERBOSE=false)."
  task :migrate => :load_config do
    # TODO
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

  desc "Create the database and load the schema."
  task :setup => [:create, "groonga:schema:load"]

  task :reset => [:drop, :setup]
end
