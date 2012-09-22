# -*- coding: utf-8; mode: ruby -*-
#
# Copyright (C) 2009-2012  Kouhei Sutou <kou@clear-code.com>
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

require 'English'

require 'pathname'
require 'rubygems'
require "jeweler"
require "packnga"

base_dir = Pathname.new(__FILE__).dirname.expand_path

@rroonga_base_dir = base_dir.parent.expand_path + 'rroonga'
rroonga_ext_dir = @rroonga_base_dir + 'ext' + "groonga"
rroonga_lib_dir = @rroonga_base_dir + 'lib'
$LOAD_PATH.unshift(rroonga_ext_dir.to_s)
$LOAD_PATH.unshift(rroonga_lib_dir.to_s)
ENV["RUBYLIB"] = "#{rroonga_lib_dir}:#{rroonga_ext_dir}:#{ENV['RUBYLIB']}"

active_groonga_lib_dir = base_dir + "lib"
$LOAD_PATH.unshift(active_groonga_lib_dir.to_s)

def guess_version
  require 'active_groonga/version'
  ActiveGroonga::VERSION::STRING
end

def cleanup_white_space(entry)
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end

ENV["VERSION"] ||= guess_version
version = ENV["VERSION"].dup
spec = nil
Jeweler::Tasks.new do |_spec|
  spec = _spec
  spec.name = "activegroonga"
  spec.version = version
  spec.rubyforge_project = "groonga"
  spec.homepage = "http://groonga.rubyforge.org/"
  spec.authors = ["Kouhei Sutou"]
  spec.email = ["kou@clear-code.com"]
  entries = File.read("README.textile").split(/^h2\.\s(.*)$/)
  description = cleanup_white_space(entries[entries.index("Description") + 1])
  spec.summary, spec.description, = description.split(/\n\n+/, 3)
  spec.license = "LGPLv2"
  spec.files = FileList["{lib,test}/**/*.rb",
                        "lib/**/railties/**/*.rake",
                        "lib/**/locale/**/*.yml",
                        "Rakefile",
                        ".yardopts",
                        "README.textile",
                        "doc/text/**/*"]
end

Rake::Task["release"].prerequisites.clear
Jeweler::RubygemsDotOrgTasks.new do
end

Packnga::DocumentTask.new(spec) do |task|
  task.reference do |reference_task|
    # reference_task.mode = "xhtml"
  end
end

Packnga::ReleaseTask.new(spec) do |task|
  task.index_html_dir = "../rroonga/doc/html"
end

task :test do
  ruby("test/run-test.rb")
end

task :default => :test
