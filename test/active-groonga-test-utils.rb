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

require 'fileutils'
require 'pathname'

require 'active_groonga'

module ActiveGroongaTestUtils
  class << self
    def included(base)
      base.setup :setup_sand_box, :before => :prepend
      base.teardown :teardown_sand_box, :after => :append
    end
  end

  def setup_sand_box
    Groonga::Context.default = nil
    @context = Groonga::Context.default

    setup_tmp_directory
    setup_database_directory
    setup_tables_directory
    setup_indexes_directory

    setup_database
    setup_users_table
    setup_bookmarks_table
    setup_bookmarks_index_table
    setup_tasks_table

    setup_user_records
    setup_bookmark_records
    setup_class
  end

  def setup_tmp_directory
    @tmp_dir = Pathname(File.dirname(__FILE__)) + "tmp"
    FileUtils.rm_rf(@tmp_dir.to_s)
    FileUtils.mkdir_p(@tmp_dir.to_s)
  end

  def setup_database_directory
    @database_dir = @tmp_dir + "database"
    FileUtils.mkdir_p(@database_dir.to_s)
    ActiveGroonga::Base.database_directory = @database_dir.to_s
  end

  def setup_tables_directory
    @tables_dir = @database_dir + "tables"
    FileUtils.mkdir_p(@tables_dir.to_s)
  end

  def setup_indexes_directory
    @indexes_dir = @database_dir + "indexes"
    FileUtils.mkdir_p(@indexes_dir.to_s)
  end

  def setup_database
    @database_path = @database_dir + "database.groonga"
    @database = Groonga::Database.create(:path => @database_path.to_s)

    ActiveGroonga::Schema.initialize_schema_management_tables
  end

  def setup_users_table
    @users_path = @tables_dir + "users.groonga"
    @users = Groonga::Array.create(:name => "<table:users>",
                                   :path => @users_path.to_s)

    columns_dir = @tables_dir + "users" + "columns"
    columns_dir.mkpath

    @name_column_path = columns_dir + "name.groonga"
    @name_column = @users.define_column("name", "<shorttext>",
                                        :path => @name_column_path.to_s)
  end

  def setup_bookmarks_table
    @bookmarks_path = @tables_dir + "bookmarks.groonga"
    @bookmarks = Groonga::Array.create(:name => "<table:bookmarks>",
                                       :path => @bookmarks_path.to_s)

    columns_dir = @tables_dir + "bookmarks" + "columns"
    columns_dir.mkpath

    @uri_column_path = columns_dir + "uri.groonga"
    @uri_column = @bookmarks.define_column("uri", "<shorttext>",
                                           :path => @uri_column_path.to_s)

    @comment_column_path = columns_dir + "comment.groonga"
    @comment_column =
      @bookmarks.define_column("comment", "<text>",
                               :path => @comment_column_path.to_s)

    @content_column_path = columns_dir + "content.groonga"
    @content_column =
      @bookmarks.define_column("content", "<longtext>",
                               :path => @content_column_path.to_s)

    @user_id_column_path = columns_dir + "user_id.groonga"
    @user_id_column =
      @bookmarks.define_column("user_id", @users,
                               :path => @user_id_column_path.to_s)
  end

  def setup_bookmarks_index_table
    bookmarks_index_path = @indexes_dir + "bookmarks"
    bookmarks_index_path.mkpath
    @bookmarks_content_index_path = bookmarks_index_path + "content.groonga"
    @bookmarks_content_index =
      Groonga::Hash.create(:name => "<index:bookmarks:content>",
                           :path => @bookmarks_content_index_path.to_s)
    @bookmarks_content_index.default_tokenizer = "<token:mecab>"

    columns_dir = bookmarks_index_path + "content" + "columns"
    columns_dir.mkpath

    @bookmarks_content_index_column_path = columns_dir + "inverted-index.groonga"
    path = @bookmarks_content_index_column_path.to_s
    @bookmarks_content_index_column =
      @bookmarks_content_index.define_column("inverted-index", "<shorttext>",
                                             :type => "index",
                                             :with_section => true,
                                             :with_weight => true,
                                             :with_position => true,
                                             :path => path)

    record = ActiveGroonga::Schema.index_management_table.add(@bookmarks.name)
    record["column"] = "content"
    record["index"] = @bookmarks_content_index.name
  end

  def setup_tasks_table
    @tasks_path = @tables_dir + "tasks.groonga"
    @tasks = Groonga::Array.create(:name => "<table:tasks>",
                                   :path => @tasks_path.to_s)

    columns_dir = @tables_dir + "tasks" + "columns"
    columns_dir.mkpath

    @name_column_path = columns_dir + "name.groonga"
    @name_column = @tasks.define_column("name", "<shorttext>",
                                        :path => @name_column_path.to_s)
  end

  def setup_user_records
    @user_records = {}

    @user_records[:daijiro] = create_user("daijiro")
    @user_records[:gunyarakun] = create_user("gunyarakun")
  end

  def setup_bookmark_records
    @bookmark_records = {}

    @bookmark_records[:groonga] =
      create_bookmark("groonga",
                      @user_records[:daijiro],
                      "http://groonga.org/",
                      "fulltext search engine",
                      "<html><body>groonga</body></html>")

    @bookmark_records[:cutter] =
      create_bookmark("cutter",
                      @user_records[:gunyarakun],
                      "http://cutter.sourceforge.net/",
                      "a unit testing framework for C",
                      "<html><body>Cutter</body></html>")
  end

  def setup_class
    base_dir = Pathname(__FILE__).parent + "fixtures"
    Object.class_eval do
      remove_const(:User) if const_defined?(:User)
      remove_const(:Bookmark) if const_defined?(:Bookmark)
      remove_const(:Task) if const_defined?(:Task)
    end
    load((base_dir + 'user.rb').to_s)
    load((base_dir + 'bookmark.rb').to_s)
    load((base_dir + 'task.rb').to_s)
  end

  def teardown_sand_box
    teardown_tmp_directory
  end

  def teardown_tmp_directory
    FileUtils.rm_rf(@tmp_dir.to_s)
  end

  private
  def create_user(name)
    user = @users.add
    user["name"] = name
    user
  end

  def create_bookmark(name, user, uri, comment, content)
    bookmark = @bookmarks.add
    bookmark["uri"] = uri
    bookmark["user_id"] = user.id
    bookmark["comment"] = comment
    bookmark["content"] = content
    @bookmarks_content_index_column[bookmark.id] = content

    bookmark
  end
end
