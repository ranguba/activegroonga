# Copyright (C) 2010  Kouhei Sutou <kou@clear-code.com>
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

class TestValidations < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def test_missing_key
    empty_site = Site.new
    assert_false(empty_site.save)
    assert_equal([message(:key, :blank)],
                 empty_site.errors.to_a)
  end

  private
  def message(key, type)
    I18n.t(:"errors.format",
           :attribute => Site.human_attribute_name(key),
           :message => I18n.t(:"errors.messages.#{type}"))
  end
end
