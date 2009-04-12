# -*- coding: utf-8 -*-

ActiveGroonga::Base.logger ||= Rails.logger

configuration_file = config.groonga_configuration_file
unless File.exist?(configuration_file)
  File.open(configuration_file, "w") do |file|
    file.puts <<-EOC
development:
  database: db/development.groonga

test:
  database: db/test.groonga

production:
  database: db/production.groonga
EOC
  end
end
ActiveGroonga::Base.configurations = config.groonga_configuration
ActiveGroonga::Base.setup_database

# class ::ActionView::Base
#   include ActiveGroonga::Helper
# end

# require 'active_groonga/action_controller/groonga_benchmarking'
# module ::ActionController
#   class Base
#     include ActiveGroonga::ActionController::GroongaBenchmarking
#   end
# end
