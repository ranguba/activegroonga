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

require 'fileutils'

module ActiveGroonga
  module Railties
    module Configurable
      def groonga_configurations
        groonga_yml = paths.config.groonga.first
        unless File.exist?(groonga_yml)
          groonga_yml_example = "#{groonga_yml}.example"
          if File.exist?(groonga_yml_example)
            FileUtils.cp(groonga_yml_example, groonga_yml)
          else
            File.open(groonga_yml, "w") do |yml|
              yml.puts(<<-EOC)
development:
  database: db/groonga/development/db

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  database: db/groonga/test/db

production:
  database: db/groonga/production/db
              EOC
            end
          end
        end
        YAML.load(ERB.new(IO.read(groonga_yml)).result)
      end
    end
  end
end
