# Copyright (C) 2010-2011  Kouhei Sutou <kou@clear-code.com>
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

class TestResultSet < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def teardown
    Bookmark.sort_keys = nil
    Bookmark.limit = nil
  end

  class TestPaginateLimit < self
    def test_implicit
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/",
                    "http://groonga.org/"].sort,
                   bookmarks.paginate(["uri"]).collect(&:uri))
    end

    def test_explicit
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.paginate(["uri"], :size => 1).collect(&:uri))
    end

    def test_explicit_override
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.paginate(["uri"], :size => 1).collect(&:uri))
    end
  end

  class TestSortLimit < self
    def test_implicit
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/",
                    "http://groonga.org/",].sort,
                   bookmarks.sort(["uri"]).collect(&:uri))
    end

    def test_explicit
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.sort(["uri"], :limit => 1).collect(&:uri))
    end

    def test_explicit_override
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.sort(["uri"], :limit => 1).collect(&:uri))
    end
  end
end
