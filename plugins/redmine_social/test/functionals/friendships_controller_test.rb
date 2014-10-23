require File.expand_path('../../../../../test/test_helper', __FILE__)

class FriendshipsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
  
  test "unable to create a friendship request if user not logged in" do
    current_user = users(:users_002)
    friend_user = users(:users_003)
    post :create, :user_id => friend_user.id
    assert !current_user.friendship_exists_with?(friend_user),
      "Friendship does not exists from #{current_user.login} to #{friend_user.login}"
  end
  
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
  
  test "friendship request can denied" do
    current_user = users(:users_002)
    friend_user = users(:users_003)

    # current_user request friendship with friend_user
    create_friendship(current_user, friend_user)
    friendship_from_friend_to_user = find_friendship(friend_user, current_user)
    
    # friend_user should can accept friendship request
    @request.session[:user_id] = friend_user.id
    put :deny, :user_id => friend_user.id, :id => friendship_from_friend_to_user.id

    friendship_from_current_to_friend = find_friendship(current_user, friend_user)
    # update friendship_from_friend_to_current
    friendship_from_friend_to_current = find_friendship(friend_user, current_user)
    
    assert friendship_from_current_to_friend.denied?,
      "Friendship from #{current_user.login} to #{friend_user.login} is denied"
    assert friendship_from_friend_to_current.denied?,
      "Friendship from #{friend_user.login} to #{current_user.login} is denied"
  end
  
  test "friendship not exists after exceeding daily request limit" do
    current_user = users(:users_002)
    limit = Friendship.daily_request_limit
    
    # create one more dummy user than the daily request limit
    dummies = []
    (1..limit + 1).each do |i|
      dummies << create_dummy_user("templogin#{i}")
    end
    
    @request.session[:user_id] = current_user.id
    
    # request friendships as much as daily request limit
    dummies[0, limit].each do |friend_user|
      post :create, :user_id => friend_user.id
    end
    
    # the limit has reached but request one more friendship
    post :create, :user_id => dummies.last.id
    
    # because the limit has reached, the last friendship should not exists
    assert !current_user.friendship_exists_with?(dummies.last),
      "Friendship does not exists from #{current_user.login} to #{dummies.last.login}"
    assert !dummies.last.friendship_exists_with?(current_user),
      "Friendship does not exists from #{dummies.last.id} to #{current_user.login}"
  end
  
  test "friendship and reverse does no more exist after destroy" do
    current_user = users(:users_002)
    friend_user = users(:users_003)
    friendship = create_friendship(current_user, friend_user)
    reverse = friendship.reverse
    
    @request.session[:user_id] = current_user.id
    assert_difference 'Friendship.count', -2 do      
      delete :destroy, :id => friendship.id, :user_id => current_user.id
    end
    assert_nil Friendship.find_by_id(friendship.id)
    assert_nil Friendship.find_by_id(reverse.id)
  end
  
  test "unable to destroy foreign friendship" do
    current_user = users(:users_002)
    friend_user = users(:users_003)
    other_user = users(:users_004)
    
    friendship = create_friendship(current_user, friend_user)
    reverse = friendship.reverse
    
    @request.session[:user_id] = other_user.id
    assert_no_difference 'Friendship.count' do      
      delete :destroy, :id => friendship.id, :user_id => current_user.id
    end
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
  
  def create_dummy_user(login)
    user = User.new(
      :login => login,
      :firstname => 'John',
      :lastname => 'Smith',
      :mail => login + "@example.net",
      :confirm => true
    )
    user.login = login
    user.save!
    return user
  end
end