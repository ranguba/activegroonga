class ScaffoldActiveGroongaGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.template("groonga.yml", File.join("config", "groonga.yml"))
    end
  end
end
