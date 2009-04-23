# -*- coding: utf-8 -*-

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "extract" do
    listener = Object.new

    title = "アンパサンド"
    timestamp = Time.parse("2008-11-17T09:17:43Z")
    contributor = {:id => 193720, :name => "鈴虫"}
    content = "{{記号文字|&amp;}} ..."
    mock(listener).title(title)
    mock(listener).timestamp(timestamp)
    mock(listener).contributor(contributor)
    mock(listener).content(content)
    mock(listener).page(:title => title,
                        :timestamp => timestamp,
                        :contributor => contributor,
                        :content => content)
    parse("ampersand-omitted.xml", listener)
  end

  private
  def parse(fixture_name, listener)
    extractor = WikipediaExtractor.new(listener)
    extractor.extract(read_fixture(fixture_name))
  end

  def read_fixture(name)
    File.read(File.join(self.class.fixture_path, "wikipedia", name))
  end
end
