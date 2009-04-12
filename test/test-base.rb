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

class BaseTest < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def test_find
    bookmarks = @bookmark_class.find(:all)
    assert_equal(["http://groonga.org/", "http://cutter.sourceforge.net/"].sort,
                 bookmarks.collect(&:uri).sort)
  end

  def test_find_by_id
    groonga = @bookmark_class.find(@bookmark_records[:groonga].id)
    assert_equal("http://groonga.org/", groonga.uri)
  end
end
