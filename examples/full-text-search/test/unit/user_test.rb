require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "find by nonexistent original-id" do
    assert_nil(User.find_by_original_id("nonexistent"))
  end

  test "find by original-id" do
    user = User.create(:original_id => "wikipedia:29")
    assert_not_nil(user)
    assert_equal(user, User.find_by_original_id("wikipedia:29"))
  end
end
