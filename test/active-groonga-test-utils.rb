# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
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
    ActiveGroonga::Base.context = nil
    Groonga::Context.default = nil
    @context = Groonga::Context.default

    setup_tmp_directory
    setup_database_directory
    setup_database
    setup_tables_directory
    setup_metadata_directory

    setup_users_table
    setup_bookmarks_table
    setup_bookmarks_index_tables
    setup_tasks_table
    setup_sites_table
    setup_pages_table

    setup_user_records
    setup_bookmark_records
    setup_class
  end

  def setup_tmp_directory
    @base_tmp_dir = Pathname(File.dirname(__FILE__)) + "tmp"
    memory_file_system = "/dev/shm"
    if File.exist?(memory_file_system)
      FileUtils.mkdir_p(@base_tmp_dir.parent.to_s)
      FileUtils.rm_f(@base_tmp_dir.to_s)
      FileUtils.ln_s(memory_file_system, @base_tmp_dir.to_s)
    else
      FileUtils.mkdir_p(@base_tmp_dir.to_s)
    end

    @tmp_dir = @base_tmp_dir + "active-groonga"
    FileUtils.rm_rf(@tmp_dir.to_s)
    FileUtils.mkdir_p(@tmp_dir.to_s)
  end

  def setup_database_directory
    @database_dir = @tmp_dir + "groonga"
    FileUtils.mkdir_p(@database_dir.to_s)
  end

  def setup_database
    @database_path = @database_dir + "database"
    @database = Groonga::Database.create(:path => @database_path.to_s)
    ActiveGroonga::Base.database_path = @database_path.to_s
  end

  def setup_tables_directory
    @tables_dir = Pathname("#{@database_path}.tables")
    FileUtils.mkdir_p(@tables_dir.to_s)
  end

  def setup_metadata_directory
    @metadata_dir = Pathname("#{@database_path}.metadata")
    FileUtils.mkdir_p(@metadata_dir.to_s)
  end

  def setup_users_table
    @users_path = @tables_dir + "users"
    @users = Groonga::Array.create(:name => "users",
                                   :path => @users_path.to_s,
                                   :sub_records => true)

    columns_dir = @tables_dir + "users.columns"
    columns_dir.mkpath

    @name_column_path = columns_dir + "name"
    @name_column = @users.define_column("name", "ShortText",
                                        :path => @name_column_path.to_s)
  end

  def setup_bookmarks_table
    @bookmarks_path = @tables_dir + "bookmarks"
    @bookmarks = Groonga::Array.create(:name => "bookmarks",
                                       :path => @bookmarks_path.to_s,
                                       :sub_records => true)

    columns_dir = @tables_dir + "bookmarks.columns"
    columns_dir.mkpath

    @uri_column_path = columns_dir + "uri"
    @uri_column = @bookmarks.define_column("uri", "ShortText",
                                           :path => @uri_column_path.to_s)

    @comment_column_path = columns_dir + "comment"
    @comment_column =
      @bookmarks.define_column("comment", "Text",
                               :path => @comment_column_path.to_s)

    @content_column_path = columns_dir + "content"
    @content_column =
      @bookmarks.define_column("content", "LongText",
                               :path => @content_column_path.to_s)

    @user_column_path = columns_dir + "user"
    @user_column =
      @bookmarks.define_column("user", @users,
                               :path => @user_column_path.to_s)

    define_timestamp(@bookmarks, columns_dir)
  end

  def define_timestamp(table, columns_dir)
    created_at_column_path = columns_dir + "created_at"
    table.define_column("created_at", "Time",
                        :path => created_at_column_path.to_s)

    updated_at_column_path = columns_dir + "updated_at"
    table.define_column("updated_at", "Time",
                        :path => updated_at_column_path.to_s)
  end

  def setup_bookmarks_index_tables
    @terms_path = @tables_dir + "terms"
    @terms = Groonga::PatriciaTrie.create(:name => "terms",
                                          :key_type => "ShortText",
                                          :path => @terms_path.to_s,
                                          :default_tokenizer => "TokenBigram")

    columns_dir = @tables_dir + "terms.columns"
    columns_dir.mkpath

    @bookmarks_comment_index_column_path = columns_dir + "bookmarks_comment"
    path = @bookmarks_comment_index_column_path.to_s
    @bookmarks_comment_index_column =
      @terms.define_index_column("bookmarks_comment", @bookmarks,
                                 :with_section => true,
                                 :with_weight => true,
                                 :with_position => true,
                                 :path => path)
    @bookmarks_comment_index_column.source = @comment_column

    @bookmarks_content_index_column_path = columns_dir + "bookmarks_content"
    path = @bookmarks_content_index_column_path.to_s
    @bookmarks_content_index_column =
      @terms.define_index_column("bookmarks_content", @bookmarks,
                                 :with_section => true,
                                 :with_weight => true,
                                 :with_position => true,
                                 :path => path)
    @bookmarks_content_index_column.source = @content_column
  end

  def setup_tasks_table
    @tasks_path = @tables_dir + "tasks"
    @tasks = Groonga::Array.create(:name => "tasks",
                                   :path => @tasks_path.to_s,
                                   :sub_records => true)

    columns_dir = @tables_dir + "tasks.columns"
    columns_dir.mkpath

    @name_column_path = columns_dir + "name"
    @name_column = @tasks.define_column("name", "ShortText",
                                        :path => @name_column_path.to_s)
  end

  def setup_sites_table
    @sites_path = @tables_dir + "sites"
    @sites = Groonga::Hash.create(:name => "sites",
                                  :key_type => "ShortText",
                                  :path => @sites_path.to_s)

    columns_dir = @tables_dir + "sites.columns"
    columns_dir.mkpath

    @title_column_path = columns_dir + "title"
    @title_column = @sites.define_column("title", "ShortText",
                                         :path => @title_column_path.to_s)
    @score_column_path = columns_dir + "score"
    @score_column = @sites.define_column("score", "UInt32",
                                         :path => @score_column_path.to_s)
  end

  def setup_pages_table
    @pages_path = @tables_dir + "pages"
    @pages = Groonga::Hash.create(:name => "pages",
                                  :key_type => "ShortText",
                                  :path => @pages_path.to_s)

    columns_dir = @tables_dir + "pages.columns"
    columns_dir.mkpath

    @site_column_path = columns_dir + "site"
    @site_column = @pages.define_column("site", @sites,
                                        :path => @site_column_path.to_s)
  end

  def setup_user_records
    @user_records = {}

    @user_records[:daijiro] = create_user("daijiro")
    @user_records[:gunyarakun] = create_user("gunyarakun")
  end

  def setup_bookmark_records
    @bookmark_records = {}

    @bookmark_records[:groonga] =
      create_bookmark(@user_records[:daijiro],
                      "http://groonga.org/",
                      "fulltext search engine",
                      "<html><body>groonga</body></html>")

    @bookmark_records[:rroonga] =
      create_bookmark(@user_records[:daijiro],
                      "http://groonga.rubyforge.org/",
                      "The Ruby bindings for groonga",
                      "<html><body>rroonga</body></html>")

    @bookmark_records[:cutter] =
      create_bookmark(@user_records[:gunyarakun],
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
      remove_const(:Site) if const_defined?(:Site)
      remove_const(:Page) if const_defined?(:Page)
    end
    load((base_dir + 'user.rb').to_s)
    load((base_dir + 'bookmark.rb').to_s)
    load((base_dir + 'task.rb').to_s)
    load((base_dir + 'site.rb').to_s)
    load((base_dir + 'page.rb').to_s)
  end

  def teardown_sand_box
    @database.close
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

  def create_bookmark(user, uri, comment, content)
    bookmark = @bookmarks.add
    bookmark["uri"] = uri
    bookmark["user"] = user
    bookmark["comment"] = comment
    bookmark["content"] = content
    bookmark["created_at"] = Time.parse("2009-02-09 02:09:29")
    bookmark["updated_at"] = Time.parse("2009-02-09 02:29:00")

    bookmark
  end
end
