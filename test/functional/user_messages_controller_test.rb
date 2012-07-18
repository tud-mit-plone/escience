require 'test_helper'

class UserMessagesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_messages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user_message" do
    assert_difference('UserMessage.count') do
      post :create, :user_message => { }
    end

    assert_redirected_to user_message_path(assigns(:user_message))
  end

  test "should show user_message" do
    get :show, :id => user_messages(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => user_messages(:one).to_param
    assert_response :success
  end

  test "should update user_message" do
    put :update, :id => user_messages(:one).to_param, :user_message => { }
    assert_redirected_to user_message_path(assigns(:user_message))
  end

  test "should destroy user_message" do
    assert_difference('UserMessage.count', -1) do
      delete :destroy, :id => user_messages(:one).to_param
    end

    assert_redirected_to user_messages_path
  end
end
