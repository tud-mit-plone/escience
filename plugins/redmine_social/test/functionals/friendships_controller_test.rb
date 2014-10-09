require File.expand_path('../../../../../test/test_helper', __FILE__)

class FriendshipsControllerTest < ActionController::TestCase
  fixtures :users
  
  test "redirect to accepted friendships after friendship request" do
    current_user = users(:users_002)
    friend_user = users(:users_003)
    
    @request.session[:user_id] = current_user.id
    post :create, :user_id => friend_user.id
    assert_redirected_to accepted_user_friendships_path(current_user)
  end

  test "corresponding friendships created after friendship request" do
    current_user = users(:users_002)
    friend_user = users(:users_003)
    
    @request.session[:user_id] = current_user.id
    post :create, :user_id => friend_user.id
    
    assert current_user.friendship_exists_with?(friend_user),
      "Friendship exists from #{current_user.login} to #{friend_user.login}"
    assert friend_user.friendship_exists_with?(current_user),
      "Friendship exists from #{friend_user.login} to #{current_user.login}"
  end
  
  test "friendships status is pending after friendship request" do
    current_user = users(:users_002)
    friend_user = users(:users_003)
    
    @request.session[:user_id] = current_user.id
    post :create, :user_id => friend_user.id
    
    friendship_from_current_to_friend = find_friendship(current_user, friend_user)
    friendship_from_friend_to_current = find_friendship(friend_user, current_user)
    
    assert friendship_from_current_to_friend.pending?,
      "Friendship from #{current_user.login} to #{friend_user.login} is pending"
    assert friendship_from_friend_to_current.pending?,
      "Friendship from #{friend_user.login} to #{current_user.login} is pending"
  end
  
  test "friendship request can accept" do
    current_user = users(:users_002)
    friend_user = users(:users_003)

    # current_user request friendship with friend_user
    create_friendship(current_user, friend_user)
    friendship_from_friend_to_user = find_friendship(friend_user, current_user)
    
    # friend_user should can accept friendship request
    @request.session[:user_id] = friend_user.id
    put :accept, :user_id => friend_user.id, :id => friendship_from_friend_to_user.id

    friendship_from_current_to_friend = find_friendship(current_user, friend_user)
    # update friendship_from_friend_to_current
    friendship_from_friend_to_current = find_friendship(friend_user, current_user)
    
    assert friendship_from_current_to_friend.accepted?,
      "Friendship from #{current_user.login} to #{friend_user.login} is accepted"
    assert friendship_from_friend_to_current.accepted?,
      "Friendship from #{friend_user.login} to #{current_user.login} is accepted"
  end
  
  private
  def find_friendship(from_user, to_user)
    Friendship.find(:first, :conditions => ["user_id = ? AND friend_id = ?",
      from_user.id, to_user.id])
  end
  
  def create_friendship(from_user, to_user)
    friendship = Friendship.new(
      :user_id => from_user.id,
      :friend_id => to_user.id,
      :initiator => true)
    friendship.friendship_status_id = FriendshipStatus[:pending].id
    reverse_friendship = Friendship.create(
      :user_id => to_user.id,
      :friend_id => from_user.id,
      :initiator => false)
    reverse_friendship.friendship_status_id = FriendshipStatus[:pending].id
    
    friendship.save!
    reverse_friendship.save!
    
    return friendship
  end
end