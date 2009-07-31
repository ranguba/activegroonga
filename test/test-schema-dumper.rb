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

class TestSchemaDumper < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def setup
    @output = StringIO.new
  end

  def test_dump
    ActiveGroonga::SchemaDumper.dump(@output)
    assert_equal(<<-EOS, @output.string.gsub(/^\s*(?:#.*)?\n/, ''))
ActiveGroonga::Schema.define(:version => 0) do
  create_table "bookmarks", :force => true do |t|
    t.string "uri"
    t.time "updated_at"
    t.time "created_at"
    t.text "content"
    t.text "comment"
  end
  create_table "tasks", :force => true do |t|
    t.string "name"
  end
  create_table "terms", :force => true, :type => :patricia_trie, :key_type => "ShortText", :default_tokenizer => "TokenBigram" do |t|
  end
  create_table "users", :force => true do |t|
    t.string "name"
  end
  add_column "bookmarks", "user", "users"
  add_index_column "terms", "bookmarks", "content", :name => "bookmarks/content"
end
EOS
  end
end
