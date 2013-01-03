# -*- coding: utf-8; mode: ruby -*-
#
# Copyright (C) 2009-2013  Kouhei Sutou <kou@clear-code.com>
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

require "English"

require "pathname"
require "rubygems"
require "bundler/gem_helper"
require "packnga"

base_dir = Pathname.new(__FILE__).dirname.expand_path

@rroonga_base_dir = base_dir.parent.expand_path + "rroonga"
rroonga_ext_dir = @rroonga_base_dir + "ext" + "groonga"
rroonga_lib_dir = @rroonga_base_dir + "lib"
$LOAD_PATH.unshift(rroonga_ext_dir.to_s)
$LOAD_PATH.unshift(rroonga_lib_dir.to_s)
ENV["RUBYLIB"] = [rroonga_lib_dir, rroonga_ext_dir, ENV["RUBYLIB"]].join(":")

helper = Bundler::GemHelper.new(base_dir)
def helper.version_tag
  version
end

helper.install
spec = helper.gemspec

Packnga::DocumentTask.new(spec) do |task|
  task.original_language = "en"
  task.translate_languages = ["ja"]
end

Packnga::ReleaseTask.new(spec) do |task|
  task.index_html_dir = "../rroonga/doc/html"
end

task :test do
  ruby("test/run-test.rb")
end

task :default => :test
