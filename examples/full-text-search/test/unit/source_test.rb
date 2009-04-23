require 'test_helper'

class SourceTest < ActiveSupport::TestCase
  test "find by name" do
    assert_equal(sources(:wikipedia_ja), Source.find_by_name("Wikipedia (ja)"))
  end
end
