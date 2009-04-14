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

class SchemaTest < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def test_create_table
    table_file = @tables_dir + "posts.groonga"
    assert_not_predicate(table_file, :exist?)
    ActiveGroonga::Schema.create_table(:posts) do |table|
    end
    assert_predicate(table_file, :exist?)
  end

  def test_string_column
    column_file = @tables_dir + "posts" + "columns" + "title.groonga"
    assert_not_predicate(column_file, :exist?)
    ActiveGroonga::Schema.create_table(:posts) do |table|
      table.string :title
    end
    assert_predicate(column_file, :exist?)
  end

  def test_add_index
    base_dir = @indexes_dir + "posts"
    index_file = base_dir + "content.groonga"
    inverted_index_file = base_dir + "content" + "inverted-index.groonga"
    assert_not_predicate(index_file, :exist?)
    assert_not_predicate(inverted_index_file, :exist?)

    ActiveGroonga::Schema.create_table(:posts) do |table|
      table.string :content
      table.index :content
    end

    assert_predicate(index_file, :exist?)
    assert_not_predicate(inverted_index_file, :exist?)
  end
end
