# Copyright (C) 2010-2011  Kouhei Sutou <kou@clear-code.com>
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

require "active_groonga"
require "rails"
require "active_model/railtie"

require "active_groonga/railties/configurable"

module ActiveGroonga
  class Railtie < Rails::Railtie
    config.active_groonga = ActiveSupport::OrderedOptions.new

    config.app_generators.orm(:active_groonga,
                              :migration => true,
                              :timestamps => true)

    config.before_configuration do
      application_config = Rails.application.config
      application_config.extend(Railties::Configurable)
      application_config.paths.add("config/groonga",
                                   :with => "config/groonga.yml")
    end

    rake_tasks do
      load "active_groonga/railties/groonga.rake"
    end

    console do
      ActiveGroonga::Base
    end

    initializer("active_groonga.logger") do
      ActiveSupport.on_load(:active_groonga) do
        self.logger ||= ::Rails.logger
      end
    end

    initializer("active_groonga.set_configurations") do |app|
      ActiveSupport.on_load(:active_groonga) do
        app.config.active_groonga.each do |key, value|
          send("#{key}=", value)
        end
      end
    end

    initializer("active_groonga.initialize_database") do |app|
      ActiveSupport.on_load(:active_groonga) do
        self.configurations = app.config.groonga_configurations
        configure(Rails.env)
        database.ensure_available
      end
    end
  end
end
