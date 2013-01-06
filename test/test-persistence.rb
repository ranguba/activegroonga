# Copyright (C) 2010-2013  Kouhei Sutou <kou@clear-code.com>
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

class TestPersistence < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def test_save_hash
    key = "http://groonga.org/"
    title = "groonga"

    site = Site.new
    site.key = key
    site.title = title
    assert_true(site.save)
    found_site = Site.find(key)
    assert_equal([key, title],
                 [found_site.key, found_site.title])
  end

  class TestCreate < self
  def test_hash
    groonga = Site.create(:key => "http://groonga.org/",
                          :title => "groonga")
    found_groonga = Site.find("http://groonga.org/")
    assert_equal(["http://groonga.org/", "groonga"],
                 [found_groonga.key, found_groonga.title])
  end
  end

  def test_update
    groonga = Site.new
    groonga.key = "http://groonga.org/"
    assert_true(groonga.save)

    groonga.title = "groonga"
    assert_true(groonga.save)

    reloaded_groonga = Site.find("http://groonga.org/")
    assert_equal(["http://groonga.org/", "groonga"],
                 [reloaded_groonga.key, reloaded_groonga.title])
  end
end
