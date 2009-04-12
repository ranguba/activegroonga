require_library_or_gem 'active_groonga'
ActiveGroonga::Base.logger ||= RAILS_DEFAULT_LOGGER

required_version = ["0", "0", "1"]
if (ActiveGroonga::VERSION.split(".") <=> required_version) < 0
  ActiveGroonga::Base.class_eval do
    format = _("You need ActiveGroonga %s or later")
    logger.error(format % required_version.join("."))
  end
end

groonga_configuration_file = File.join(RAILS_ROOT, 'config', 'groonga.yml')
if File.exist?(groonga_configuration_file)
  configurations = YAML.load(ERB.new(IO.read(groonga_configuration_file)).result)
  ActiveGroonga::Base.configurations = configurations
  ActiveGroonga::Base.setup_connection
else
  ActiveGroonga::Base.class_eval do
    format = _("You should run 'script/generator scaffold_active_groonga' to make %s.")
    logger.error(format % groonga_configuration_file)
  end
end

class ::ActionView::Base
  include ActiveGroonga::Helper
end

require 'active_groonga/action_controller/groonga_benchmarking'
module ::ActionController
  class Base
    include ActiveGroonga::ActionController::GroongaBenchmarking
  end
end
