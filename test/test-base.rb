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

  def test_create
    google = @bookmark_class.new
    google.uri = "http://google.com/"
    google.comment = "a search engine"
    assert_nil(google.id)
    google.save
    assert_not_nil(google.id)

    reloaded_google = @bookmark_class.find(google.id)
    assert_equal("http://google.com/", reloaded_google.uri)
  end

  def test_update
    groonga_id = @bookmark_records[:groonga].id
    groonga = @bookmark_class.find(groonga_id)
    groonga.comment = "a search engine"
    assert_equal(groonga_id, groonga.id)
    groonga.save
    assert_not_nil(groonga_id, groonga.id)

    reloaded_groonga = @bookmark_class.find(groonga.id)
    assert_equal("a search engine", reloaded_groonga.comment)
  end
end
