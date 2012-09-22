# -*- encoding: utf-8 -*-
require File.expand_path('../lib/active_groonga/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kouhei Sutou"]
  gem.email         = ["kou@clear-code.com"]
  gem.description   = %q{A library to use groonga with ActiveRecord like API.}
  gem.summary       = %q{groonga with ActiveRecord like API}
  gem.homepage      = "http://ranguba.org/"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "activegroonga"
  gem.require_paths = ["lib"]
  gem.version       = ActiveGroonga::VERSION::STRING
end
