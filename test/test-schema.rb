# Copyright (C) 2009-2010  Kouhei Sutou <kou@clear-code.com>
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

class TestSchema < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def test_create_table
    table_file = @tables_dir + "posts"
    assert_not_predicate(table_file, :exist?)
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
      end
    end
    assert_predicate(table_file, :exist?)
  end

  def test_string_column
    column_file = @tables_dir + "posts.columns" + "title"
    assert_not_predicate(column_file, :exist?)
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
        table.string :title
      end
    end
    assert_predicate(column_file, :exist?)
  end

  def test_reference_column
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:categories) do |table|
        table.string(:name)
      end
    end

    column_file = @tables_dir + "posts.columns" + "category"
    assert_not_predicate(column_file, :exist?)
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
        table.reference(:category)
      end
    end
    assert_predicate(column_file, :exist?)
  end

  def test_add_index
    columns_dir = @tables_dir + "words.columns"
    index_file = columns_dir + "posts_content"
    assert_not_predicate(index_file, :exist?)

    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
        table.string(:content)
      end

      schema.create_table(:words) do |table|
        table.index(:posts, :content)
      end
    end

    assert_predicate(index_file, :exist?)
  end

  def test_remove_column
    column_file = @tables_dir + "posts.columns" + "title"
    assert_not_predicate(column_file, :exist?)
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
        table.string(:title)
      end
    end
    assert_predicate(column_file, :exist?)

    ActiveGroonga::Schema.define do |schema|
      schema.remove_column(:posts, :title)
    end
    assert_not_predicate(column_file, :exist?)
  end

  def test_dump
    assert_equal(<<-EOS, ActiveGroonga::Schema.dump)
ActiveGroonga::Schema.define(:version => 0) do |schema|
  schema.instance_eval do
    create_table("bookmarks",
                 :force => true) do |table|
      table.text("comment")
      table.long_text("content")
      table.time("created_at")
      table.time("updated_at")
      table.short_text("uri")
    end

    create_table("tasks",
                 :force => true) do |table|
      table.short_text("name")
    end

    create_table("terms",
                 :type => :patricia_trie,
                 :key_type => "ShortText",
                 :force => true) do |table|
    end

    create_table("users",
                 :force => true) do |table|
      table.short_text("name")
    end

    change_table("bookmarks") do |table|
      table.reference("user", "users")
    end

    change_table("terms") do |table|
      table.index("bookmarks", "content", :name => "bookmarks_content")
    end
  end
end
EOS
  end
end
