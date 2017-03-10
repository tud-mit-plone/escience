require File.expand_path('../../test_helper', __FILE__)

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

  test "unable to get index page if not logged in" do
    get :index, :user_id => users(:users_002)
    assert_response :redirect
  end

  test "index shows accpeted and pending friendships" do
    current_user = users(:users_002)

    # create 3 pending Friendships (waiting to be accepted by current_user)
    create_friendship(users(:users_003), current_user)
    create_friendship(users(:users_004), current_user)
    create_friendship(users(:users_005), current_user)

    # create 2 accepted Friendships
    friendship = create_friendship(current_user, users(:users_006))
    friendship.friendship_status_id = FriendshipStatus[:accepted].id
    friendship.save!
    reverse = friendship.reverse
    reverse.friendship_status_id = FriendshipStatus[:accepted].id
    reverse.save!

    friendship = create_friendship(current_user, users(:users_007))
    friendship.friendship_status_id = FriendshipStatus[:accepted].id
    friendship.save!
    reverse = friendship.reverse
    reverse.friendship_status_id = FriendshipStatus[:accepted].id
    reverse.save!

    # get index page
    @request.session[:user_id] = current_user.id
    get :index, :user_id => current_user.id
    assert_response :success
    assert_template :index

    # ensure the right assignments for template
    assert_equal 3, assigns(:pending_friendships_count)
    assert_equal 2, assigns(:friend_count)
    # pending friendships (waiting to be accepted by current_user)
    waiting_friendships = assigns(:waiting_friendships)
    assert_not_nil waiting_friendships
    assert waiting_friendships.any? {|fs| fs.friend_id == users(:users_003).id}
    assert waiting_friendships.any? {|fs| fs.friend_id == users(:users_004).id}
    assert waiting_friendships.any? {|fs| fs.friend_id == users(:users_005).id}
    assert_equal 3, waiting_friendships.all.count
    # accepted friendships
    friendships = assigns(:friendships)
    assert_not_nil friendships
    assert friendships.any? {|fs| fs.friend_id == users(:users_006).id}
    assert friendships.any? {|fs| fs.friend_id == users(:users_007).id}
    assert_equal 2, friendships.all.count
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

  test "unable to get pending if not logged in" do
    get :pending, :user_id => users(:users_002).id
    assert_response :redirect
  end

  test "pending shows pending friendships" do
    current_user = users(:users_002)
    # create 2 pending friendships (waiting for current_user to be accepted)
    create_friendship(users(:users_003), current_user)
    create_friendship(users(:users_004), current_user)

    # create 1 pending friendships (initiated by current_user)
    create_friendship(current_user, users(:users_005))

    @request.session[:user_id] = current_user.id
    get :pending, :user_id => current_user.id
    assert_response :success
    assert_template :pending

    friendships = assigns(:friendships)
    assert_not_nil friendships
    assert friendships.any? {|fs| fs.friend_id == users(:users_003).id}
    assert friendships.any? {|fs| fs.friend_id == users(:users_004).id}
    assert_equal 2, friendships.all.count

    waiting_friendships = assigns(:waiting_friendships)
    assert_not_nil waiting_friendships
    assert waiting_friendships.any? {|fs| fs.friend_id == users(:users_005).id}
    assert_equal 1, waiting_friendships.all.count
  end

  test "unable to get denied if not logged in" do
    get :denied, :user_id => users(:users_002).id
    assert_response :redirect
  end

  test "denied shows denied friendships" do
    current_user = users(:users_002)
    # create 2 denied friendships
    friendship = create_friendship(current_user, users(:users_003))
    friendship.friendship_status_id = FriendshipStatus[:denied].id
    friendship.save!
    reverse = friendship.reverse
    reverse.friendship_status_id = FriendshipStatus[:denied].id
    reverse.save!

    friendship = create_friendship(current_user, users(:users_004))
    friendship.friendship_status_id = FriendshipStatus[:denied].id
    friendship.save!
    reverse = friendship.reverse
    reverse.friendship_status_id = FriendshipStatus[:denied].id
    reverse.save!

    # get denied friendships
    @request.session[:user_id] = current_user.id
    get :denied, :user_id => current_user.id
    assert_response :success
    assert_template :denied

    friendships = assigns(:friendships)
    assert_not_nil friendships
    assert friendships.any? {|fs| fs.friend_id == users(:users_003).id}
    assert friendships.any? {|fs| fs.friend_id == users(:users_004).id}
    assert_equal 2, friendships.all.count
  end

  test "denied pagination works" do
    current_user = users(:users_002)

    # number of elements per page
    per_page = 30

    # create 65 dummy user
    dummys = []
    (1..65).each do |i|
      dummys << create_dummy_user("dummy_login#{i}")
    end

    SECONDS_PER_DAY = 24 * 60 * 60
    seconds = 0
    # create 65 denieded friendships ...
    dummys.each do |dummy|
      # ... on different days to avoid daily friendship limit
      # seconds since 1969-12-31 18:00:00 -0600
      seconds += SECONDS_PER_DAY
      Time.stubs(:now).returns(Time.at(seconds))
      
      friendship = create_friendship(current_user, dummy)
      friendship.friendship_status_id = FriendshipStatus[:denied].id
      friendship.save!
      reverse = friendship.reverse
      reverse.friendship_status_id = FriendshipStatus[:denied].id
      reverse.save!
    end

    # get all 3 pages
    @request.session[:user_id] = current_user.id

    # page 1 has 30 items
    get :denied, :user_id => current_user.id, :page => 1
    assert_response :success
    friendships = assigns(:friendships)
    assert_not_nil friendships
    assert_equal per_page, friendships.all.count

    # page 2 has 30 items
    get :denied, :user_id => current_user.id, :page => 2
    assert_response :success
    friendships = assigns(:friendships)
    assert_not_nil friendships
    assert_equal per_page, friendships.all.count

    # page 3 has 5 items
    get :denied, :user_id => current_user.id, :page => 3
    assert_response :success
    friendships = assigns(:friendships)
    assert_not_nil friendships
    assert_equal 65 % per_page, friendships.all.count
  end

  test "unable to get accepted if not logged in" do
    get :accepted, :user_id => users(:users_002).id
    assert_response :redirect
  end
  
  test "accepted returns accepted friendships" do
    current_user = users(:users_002)
    
    # create 3 pending friendships (waiting for current_user to be accepted)
    create_friendship(users(:users_003), current_user)
    create_friendship(users(:users_004), current_user)
    create_friendship(users(:users_005), current_user)
    
    # create 2 accepted friendships
    friendship = create_friendship(current_user, users(:users_006))
    friendship.friendship_status_id = FriendshipStatus[:accepted].id
    friendship.save!
    reverse = friendship.reverse
    reverse.friendship_status_id = FriendshipStatus[:accepted].id
    reverse.save!

    friendship = create_friendship(current_user, users(:users_007))
    friendship.friendship_status_id = FriendshipStatus[:accepted].id
    friendship.save!
    reverse = friendship.reverse
    reverse.friendship_status_id = FriendshipStatus[:accepted].id
    reverse.save!

    # get accepted friendships
    @request.session[:user_id] = current_user.id
    get :accepted, :user_id => current_user.id
    assert_response :success
    assert_template :accepted

    friendships = assigns(:friendships)
    assert_not_nil friendships
    assert friendships.any? {|fs| fs.friend_id == users(:users_006).id}
    assert friendships.any? {|fs| fs.friend_id == users(:users_007).id}
    assert_equal 2, friendships.all.count
    assert_equal 2, assigns(:friend_count)
    
    assert_equal 3, assigns(:pending_friendships_count)
  end
  
  test "unable to get show if not logged in" do
    current_user = users(:users_002)
    friendship = create_friendship(users(:users_003), current_user)
    
    get :show, :user_id => current_user.id, :id => friendship.id
    assert_response :redirect
  end
  
  test "show assigns right friendship" do
    current_user = users(:users_002)
    friend_user = users(:users_003)
    friendship = create_friendship(current_user, friend_user)
    
    @request.session[:user_id] = current_user.id
    get :show, :user_id => current_user.id, :id => friend_user.id
    assert_response :success
    assert_template partial: '_friendship'
    template_friendship = assigns(:friendship)
    assert_not_nil template_friendship
    assert_equal friendship.id, template_friendship.id
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