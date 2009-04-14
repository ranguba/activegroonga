# -*- coding: utf-8 -*-

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "extract" do
    listener = Object.new
    mock(listener).title("アンパサンド")
    mock(listener).timestamp(Time.parse("2008-11-17T09:17:43Z"))
    mock(listener).contributor({:id => 193720, :name => "鈴虫"})
    mock(listener).content("{{記号文字|&amp;}} ...")
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
