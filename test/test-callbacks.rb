# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

class TestCallbacks < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def test_before_save
    bookmark = Bookmark.new
    def bookmark.before_save
      @called = true
    end
    bookmark.instance_variable_set("@called", false)
    assert_equal(false, bookmark.instance_variable_get("@called"))
    bookmark.save
    assert_equal(true, bookmark.instance_variable_get("@called"))
  end
end
