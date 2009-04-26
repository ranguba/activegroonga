# -*- coding: utf-8 -*-

ActiveGroonga::Base.logger ||= Rails.logger

case Rails.logger.level
when ActiveSupport::BufferedLogger::DEBUG
  log_level = :debug
when ActiveSupport::BufferedLogger::INFO
  log_level = :info
when ActiveSupport::BufferedLogger::WARN
  log_level = :warning
when ActiveSupport::BufferedLogger::ERROR
  log_level = :error
when ActiveSupport::BufferedLogger::FATAL
  log_level = :critical
when ActiveSupport::BufferedLogger::UNKNOWN
  log_level = :none
else
  log_level = :info
end
options = {:level => log_level}
Groonga::Logger.register(options) do |level, time, title, message, location|
  logger = ActiveGroonga::Base.logger
  method_name = :info
  case level
  when :debug
    method_name = :debug
  when :info
    method_name = :info
  when :warning
    method_name = :warn
  when :error
    method_name = :error
  when :critical
    method_name = :fatal
  when :none
    method_name = :unknown
  end
  message = "[#{title}] #{message}" unless title.blank?
  logger.send(method_name, message)
end

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
