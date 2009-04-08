#!/usr/bin/env ruby
#
# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
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

base_dir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
test_unit_dir = File.join(base_dir, "test-unit", "lib")
lib_dir = File.join(base_dir, "lib")
test_dir = File.join(base_dir, "test")

$LOAD_PATH.unshift(test_unit_dir)

require 'test/unit'

$LOAD_PATH.unshift(lib_dir)

$LOAD_PATH.unshift(test_dir)
require 'active-groonga-test-utils'

Dir.glob("test/**/test{_,-}*.rb") do |file|
  require file.sub(/\.rb$/, '')
end

exit Test::Unit::AutoRunner.run(false)
