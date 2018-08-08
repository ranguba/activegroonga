#!/usr/bin/env ruby
#
# Copyright (C) 2009-2018  Kouhei Sutou <kou@clear-code.com>
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

$VERBOSE = true

require 'pathname'
require 'shellwords'

require "rubygems"
gem "test-unit"
require "test/unit"
require "test/unit/notify"

base_dir = Pathname(__FILE__).dirname.parent.expand_path

lib_dir = base_dir + "lib"
test_dir = base_dir + "test"

rroonga_dir = base_dir.parent + "rroonga"
rroonga_makefile = rroonga_dir + "Makefile"
if rroonga_makefile.exist?
  make = nil
  if system("which gmake > /dev/null")
    make = "gmake"
  elsif system("which make > /dev/null")
    make = "make"
  end
  if make
    escaped_rroonga_dir = Shellwords.escape(rroonga_dir.to_s)
    system("cd #{escaped_rroonga_dir} && #{make} > /dev/null") or exit(false)
  end
  $LOAD_PATH.unshift(rroonga_dir + "ext" + "groonga")
  $LOAD_PATH.unshift(rroonga_dir + "lib")
end

ENV["TEST_UNIT_MAX_DIFF_TARGET_STRING_SIZE"] = "10000"

Test::Unit::Priority.enable

$LOAD_PATH.unshift(lib_dir)

$LOAD_PATH.unshift(test_dir)
require 'active-groonga-test-utils'

Dir.glob(test_dir + "**/test{_,-}*.rb") do |file|
  require file.sub(/\.rb$/, '')
end

success = Test::Unit::AutoRunner.run do |runner|
  runner.runner_options[:show_detail_immediately] = true
end
exit(success)
