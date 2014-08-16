# -*- mode: ruby; coding: utf-8 -*-
#
# Copyright (C) 2012-2013  Kouhei Sutou <kou@clear-code.com>
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

base_dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join(base_dir, "lib"))

require "active_groonga/version"

clean_white_space = lambda do |entry|
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end

Gem::Specification.new do |spec|
  spec.name = "activegroonga"
  spec.version = ActiveGroonga::VERSION::STRING.dup
  spec.homepage = "http://ranguba.org/#about-active-groonga"
  spec.authors = ["Kouhei Sutou"]
  spec.email = ["kou@clear-code.com"]

  entries = File.read("README.textile").split(/^h2\.\s(.*)$/)
  description = clean_white_space.call(entries[entries.index("Description") + 1])
  spec.summary, spec.description, = description.split(/\n\n+/, 3)

  spec.license = "LGPLv2"
  spec.files = ["README.textile", "Rakefile"]
  spec.files += [".yardopts", "#{spec.name}.gemspec"]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("lib/**/railties/**/*.rake")
  spec.files += Dir.glob("lib/**/locale/**/*.yml")
  spec.files += Dir.glob("doc/text/**/*")
  spec.test_files += Dir.glob("test/**/*.rb")

  spec.add_runtime_dependency("rroonga", ">= 2.1.2")
  spec.add_runtime_dependency("activemodel", ">= 4.0.0")
  spec.add_development_dependency("test-unit")
  spec.add_development_dependency("test-unit-notify")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("bundler")
  spec.add_development_dependency("packnga", ">= 0.9.7")
  spec.add_development_dependency("RedCloth")
end
