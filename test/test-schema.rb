# Copyright (C) 2009-2011  Kouhei Sutou <kou@clear-code.com>
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
    assert_nil(@context["posts"])
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
      end
    end
    assert_not_nil(@context["posts"])
  end

  def test_string_column
    assert_nil(@context["posts.title"])
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
        table.string :title
      end
    end
    assert_not_nil(@context["posts.title"])
  end

  def test_reference_column
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:categories) do |table|
        table.string(:name)
      end
    end

    assert_nil(@context["posts.category"])
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
        table.reference(:category)
      end
    end
    assert_not_nil(@context["posts.category"])
  end

  def test_add_index
    assert_nil(@context["words.posts_content"])

    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
        table.string(:content)
      end

      schema.create_table(:words) do |table|
        table.index(:posts, :content)
      end
    end

    assert_not_nil(@context["words.posts_content"])
  end

  def test_remove_column
    assert_nil(@context["posts.title"])
    ActiveGroonga::Schema.define do |schema|
      schema.create_table(:posts) do |table|
        table.string(:title)
      end
    end
    assert_not_nil(@context["posts.title"])

    ActiveGroonga::Schema.define do |schema|
      schema.remove_column(:posts, :title)
    end
    assert_nil(@context["posts.title"])
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

    create_table("pages",
                 :type => :hash,
                 :key_type => "ShortText",
                 :force => true) do |table|
    end

    create_table("sites",
                 :type => :hash,
                 :key_type => "ShortText",
                 :force => true) do |table|
      table.unsigned_integer32("score")
      table.short_text("title")
    end

    create_table("tasks",
                 :force => true) do |table|
      table.short_text("name")
    end

    create_table("terms",
                 :type => :patricia_trie,
                 :key_type => "ShortText",
                 :default_tokenizer => "TokenBigram",
                 :force => true) do |table|
    end

    create_table("users",
                 :force => true) do |table|
      table.short_text("name")
    end

    change_table("bookmarks") do |table|
      table.reference("user", "users")
    end

    change_table("pages") do |table|
      table.reference("site", "sites")
    end

    change_table("terms") do |table|
      table.index("bookmarks", "comment", :name => "bookmarks_comment")
      table.index("bookmarks", "content", :name => "bookmarks_content")
    end
  end
end
EOS
  end
end
