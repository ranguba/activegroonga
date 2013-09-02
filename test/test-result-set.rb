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

  class TestPaginate < self
    def test_explicit
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.paginate(["uri"], :size => 1).collect(&:uri))
    end
  end

  class TestPaginateSortKeys < self
    def test_implicit
      Bookmark.sort_keys = ["uri"]
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.paginate(:size => 1).collect(&:uri))
    end

    def test_explicit
      Bookmark.sort_keys = ["uri"]
      bookmarks = Bookmark.select
      assert_equal([User.find(@user_records[:daijiro].id)].sort,
                   bookmarks.paginate(["user"], :size => 1).collect(&:user))
    end
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
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.paginate(["uri"], :size => 1).collect(&:uri))
    end
  end

  class TestPaginateAll < self
    def test_implicit
      Bookmark.sort_keys = ["uri"]
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.paginate(:size => 1).collect(&:uri))
    end

    def test_explicit
      Bookmark.sort_keys = ["uri"]
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal([User.find(@user_records[:daijiro].id)].sort,
                   bookmarks.paginate(["user"], :size => 1).collect(&:user))
    end
  end

  class TestSort < self
    def test_explicit
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.sort(["uri"], :limit => 1).collect(&:uri))
    end
  end

  class TestSortSortKeys < self
    def test_implicit
      Bookmark.sort_keys = ["uri"]
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.sort(:limit => 1).collect(&:uri))
    end

    def test_explicit
      Bookmark.sort_keys = ["uri"]
      bookmarks = Bookmark.select
      assert_equal([User.find(@user_records[:daijiro].id)].sort,
                   bookmarks.sort(["user"], :limit => 1).collect(&:user))
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
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/"].sort,
                   bookmarks.sort(["uri"], :limit => 1).collect(&:uri))
    end
  end

  class TestSortAll < self
    def test_implicit
      Bookmark.sort_keys = ["uri"]
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal(["http://cutter.sourceforge.net/",
                    "http://groonga.org/"].sort,
                   bookmarks.sort.collect(&:uri))
    end

    def test_explicit
      Bookmark.sort_keys = ["uri"]
      Bookmark.limit = 2
      bookmarks = Bookmark.select
      assert_equal([User.find(@user_records[:daijiro].id)].sort,
                   bookmarks.sort(["user"], :limit => 1).collect(&:user))
    end
  end

  class TestEach < self
    def test_records_of_hash_without_score
      groonga = Site.create(:key => "http://groonga.org/",
                            :title => "groonga")
      Page.create(:key => "http://groonga.org/doc/",
                  :site => groonga)
      assert_nothing_raised {Page.select.each {|r| r}}
    end
  end

  class TestEmpty < self
    def test_have_records
      all_bookmarks = Bookmark.all
      assert_not_predicate(all_bookmarks, :empty?)
    end

    def test_not_have_records
      no_bookmarks = Bookmark.select do |bookmark|
        bookmark.uri == "http://example.com/"
      end
      assert_predicate(no_bookmarks, :empty?)
    end
  end
end
