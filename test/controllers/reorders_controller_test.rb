require 'test_helper'

class ReordersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get '/calendar'
    assert_response :success
  end

end
