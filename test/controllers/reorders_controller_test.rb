require 'test_helper'

class ReordersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get reorders_index_url
    assert_response :success
  end

end
