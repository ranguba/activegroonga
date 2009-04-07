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
    setup_database
    setup_table
    setup_records
    setup_class
  end

  def setup_tmp_directory
    @tmp_dir = Pathname(File.dirname(__FILE__)) + "tmp"
    FileUtils.rm_rf(@tmp_dir.to_s)
    FileUtils.mkdir_p(@tmp_dir.to_s)
  end

  def setup_database
    @db_path = @tmp_dir + "db"
    @database = Groonga::Database.create(:path => @db_path.to_s)
  end

  def setup_table
    @tables_dir = @tmp_dir + "tables"
    @tables_dir.mkdir

    @bookmarks_path = @tables_dir + "bookmarks"
    @bookmarks = Groonga::Array.create(:name => "bookmarks",
                                       :path => @bookmarks_path.to_s)

    @uri_column = @bookmarks.define_column("uri", "<shorttext>")
    @comment_column = @bookmarks.define_column("comment", "<text>")
#     @content_column = @bookmarks.define_column("content", "<longtext>",
#                                                :type => "index",
#                                                :with_section => true,
#                                                :with_weight => true,
#                                                :with_position => true)
  end

  def setup_records
    @bookmark_records = {}

    @bookmark_records[:groonga] = groonga_id = @bookmarks.add
    @uri_column[groonga_id] = "http://groonga.org/"
    @comment_column[groonga_id] = "fulltext search engine"
#     @content_column[groonga_id] = "<html>...</html>"

    @bookmark_records[:cutter] = cutter_id = @bookmarks.add
    @uri_column[cutter_id] = "http://cutter.souceforge.net/"
    @comment_column[cutter_id] = "a unit testing framework for C"
#     @content_column[cutter_id] = "<html>xxx</html>"
  end

  def setup_class
    @bookmark_class = Class.new(ActiveGroonga::Base)
  end

  def teardown_sand_box
    teardown_tmp_directory
  end

  def teardown_tmp_directory
    FileUtils.rm_rf(@tmp_dir.to_s)
  end

end
