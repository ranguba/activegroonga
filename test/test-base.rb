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

class TestBase < Test::Unit::TestCase
  include ActiveGroongaTestUtils

  def test_select
    bookmarks = Bookmark.select
    assert_equal(["http://groonga.org/",
                  "http://groonga.rubyforge.org/",
                  "http://cutter.sourceforge.net/"].sort,
                 bookmarks.collect(&:uri).sort)
  end

  def test_find
    groonga = Bookmark.find(@bookmark_records[:groonga].id)
    assert_equal("http://groonga.org/", groonga.uri)
  end

  def test_select_by_attribute
    daijiro = User.select {|record| record.name == "daijiro"}.first
    assert_equal("daijiro", daijiro.name)
  end

  def test_create
    assert_predicate(Task.count, :zero?)
    send_mail = Task.new
    send_mail.name = "send mails"
    assert_nil(send_mail.id)
    assert_true(send_mail.save)
    assert_not_nil(send_mail.id)

    reloaded_send_mail = Task.find(send_mail.id)
    assert_equal("send mails", send_mail.name)
  end

  def test_update
    groonga_id = @bookmark_records[:groonga].id
    groonga = Bookmark.find(groonga_id)
    groonga.comment = "a search engine"
    assert_equal(groonga_id, groonga.id)
    groonga.save
    assert_not_nil(groonga_id, groonga.id)

    reloaded_groonga = Bookmark.find(groonga.id)
    assert_equal("a search engine", reloaded_groonga.comment)
  end

  def test_mass_assignments
    google = Bookmark.new
    google.attributes = {
      "uri" => "http://google.com/",
      "comment" => "a search engine"
    }
    assert_true(google.save)

    reloaded_google = Bookmark.find(google.id)
    assert_equal({
                   "uri" => "http://google.com/",
                   "comment" => "a search engine",
                   "content" => nil,
                   "user" => nil,
                   "created_at" => google.created_at,
                   "updated_at" => google.updated_at,
                 },
                 reloaded_google.attributes)
  end

  def test_mass_updates
    groonga = Bookmark.select do |record|
      record.uri == "http://groonga.org/"
    end.first
    groonga.update_attributes({
                                "uri" => "http://google.com/",
                                "comment" => "a search engine",
                              })
    groonga.reload

    google = Bookmark.find(groonga.id)
    assert_equal({
                   "uri" => "http://google.com/",
                   "comment" => "a search engine",
                   "content" => groonga.content,
                   "user" => groonga.user,
                   "created_at" => groonga.created_at,
                   "updated_at" => groonga.updated_at,
                 },
                 google.attributes)
  end

  def test_destroy
    before_count = Bookmark.count
    Bookmark.select {|record| record.uri == "http://groonga.org/"}.first.destroy
    assert_equal(before_count - 1, Bookmark.count)
  end

  def test_inspect
    assert_equal("Bookmark(comment: Text, content: LongText, " +
                 "created_at: Time, updated_at: Time, " +
                 "uri: ShortText, user: users)",
                 Bookmark.inspect)

    daijiro = User.select {|record| record.name == "daijiro"}.first
    groonga = Bookmark.select {|record| record.uri == "http://groonga.org/"}.first
    assert_equal("#<Bookmark " +
                 "id: #{groonga.id}, " +
                 "comment: \"fulltext search engine\", " +
                 "content: \"<html><body>groonga</body></html>\", " +
                 "created_at: #{daijiro.created_at.inspect}, " +
                 "updated_at: #{daijiro.updated_at.inspect}, " +
                 "uri: \"http://groonga.org/\", " +
                 "user: #{daijiro.inspect}>",
                 groonga.inspect)
  end

  def test_update_inverted_index
    google = Bookmark.new
    google.attributes = {
      "uri" => "http://google.com/",
      "comment" => "a search engine",
      "content" => "<html><body>...Google...</body></html>",
    }
    google.save!

    bookmarks = Bookmark.select {|record| record["content"] =~ "Google"}
    assert_equal([google], bookmarks.to_a)

    google.content = "<html><body>...Empty...</body></html>"
    google.save!

    bookmarks = Bookmark.select {|record| record["content"] =~ "Google"}
    assert_equal([], bookmarks.to_a)

    bookmarks = Bookmark.select {|record| record["content"] =~ "Empty"}
    assert_equal([google], bookmarks.to_a)
  end

  def test_update_index
    daijiro = @user_records[:daijiro]
    google = Bookmark.new
    google.attributes = {
      "uri" => "http://google.com/",
      "user" => User.find(daijiro.id),
    }
    google.save!

    bookmarks = Bookmark.select do |record|
      record.user == daijiro
    end
    assert_equal([Bookmark.find(@bookmark_records[:groonga].id),
                  Bookmark.find(@bookmark_records[:rroonga].id),
                  google],
                 bookmarks.to_a)
  end

  def test_find_reference_by_id
    daijiro = @user_records[:daijiro]
    bookmarks = Bookmark.select {|record| record.user == daijiro}
    assert_equal([Bookmark.find(@bookmark_records[:groonga]),
                  Bookmark.find(@bookmark_records[:rroonga])],
                 bookmarks.to_a)
  end

  def test_find_all_with_block
    google = Bookmark.create("uri" => "http://google.com/",
                             "comment" => "a search engine",
                             "content" => "<html><body>...Google...</body></html>")

    assert_equal([google],
                 Bookmark.select {|record| record["content"] =~ "Google"}.to_a)
  end

  def test_find_by_model
    google = Bookmark.create("uri" => "http://google.com/",
                             "comment" => "a search engine")
    assert_equal(google, Bookmark.find(google))
  end

  def test_timestamp
    google = Bookmark.create("uri" => "http://google.com/",
                             "comment" => "a search engine")
    assert_not_equal(Time.at(0), google.created_at)
    assert_equal(Time.at(0), google.updated_at)
  end

  def test_reload
    records = Bookmark.select {|record| record.uri == "http://groonga.org/"}
    groonga = records.first
    groonga.comment = "changed!"
    assert_equal("changed!", groonga.comment)
    groonga.reload
    assert_equal("fulltext search engine", groonga.comment)
  end

  def test_find_column_access_by_method
    google = Bookmark.create("uri" => "http://google.com/",
                             "comment" => "a search engine",
                             "content" => "<html><body>Google</body></html>")


    assert_equal([google],
                 Bookmark.select {|record| record.content =~ "Google"}.to_a)
  end

  def test_exists?
    daijiro = @user_records[:daijiro]
    assert_true(User.exists?(daijiro.record_id))
    daijiro.delete
    assert_false(User.exists?(daijiro.record_id))
  end

  def test_score
    bookmarks = Bookmark.select do |record|
      target = record.match_target do |match_record|
        (match_record.content * 10) |
          (match_record.comment * 5)
      end
      target =~ "groonga"
    end
    assert_equal([["http://groonga.org/", 10],
                  ["http://groonga.rubyforge.org/", 5]],
                 bookmarks.collect {|bookmark| [bookmark.uri, bookmark.score]})
  end
end
