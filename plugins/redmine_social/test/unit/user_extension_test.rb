require File.expand_path('../../../../../test/test_helper', __FILE__)

class UserExtensionTest < ActiveSupport::TestCase
  fixtures :users, :members, :projects, :roles, :member_roles, :auth_sources,
            :trackers, :issue_statuses,
            :projects_trackers,
            :watchers,
            :issue_categories, :enumerations, :issues,
            :journals, :journal_details,
            :groups_users,
            :enabled_modules,
            :workflows
            
  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
                            [:photos])

  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end

  
  test "security hash" do
    security_hash = User.security_hash
    assert_equal "1", security_hash[:searchable_sql]
    assert_equal "2", security_hash[:account_readable_for_user]
  end
  
  test "calc security number" do
    security_number_1 = User.calc_security_number(User.security_hash)
    assert_equal 3, security_number_1
    
    security_hash = {:searchable_sql => '2', :account_readable_for_user => '3', :test_entry => '5'}
    security_number_2 = User.calc_security_number(security_hash)
    assert_equal 3, security_number_2
  end
  
  test "method missing" do
    assert_equal 1, User.method_missing("searchable_sql")
    assert_equal 2, User.method_missing("account_readable_for_user")
  end
  
  test "avatar_photo_url" do
    user_1 = users(:users_002)
    photo = Photo.find(1)
    path_before = user_1.avatar_photo_url
    user_1.avatar_id = photo.id
    path_after = user_1.avatar_photo_url
    assert_not_equal path_before, path_after
  end
  
  test "selected security options" do
    user = users(:users_002)
   
    # user.security_number = 0
    assert_empty user.selected_security_options

    user.security_number = 1
    assert_not_empty user.selected_security_options
    assert_equal 1, user.selected_security_options.length
    assert_equal :searchable_sql, user.selected_security_options.last
    
    user.security_number = 2
    assert_not_empty user.selected_security_options
    assert_equal 1, user.selected_security_options.length
    assert_equal :account_readable_for_user, user.selected_security_options.last
    
    user.security_number = 3
    assert_not_empty user.selected_security_options
    assert_equal 2, user.selected_security_options.length
    assert_equal :searchable_sql, user.selected_security_options.first
    assert_equal :account_readable_for_user, user.selected_security_options.last
    
    # user.security_number > 3
    user.security_number = 4
    assert_empty user.selected_security_options
  end
  
  test "sort" do
    user = users(:users_002)
    sortedUser = user.sort
    assert_equal "SmithJohn", sortedUser  
  end
  
  test "can request friendship with" do
    user = users(:users_002)
    friend = users(:users_003)
    no_friend = users(:users_004)
    
    friendship = Friendship.create(
        :friendship_status => FriendshipStatus[:accepted],
        :user => user,
        :friend => friend,
        :initiator => true
    )
    
    # can't do a friendship request with yourself 
    assert !user.can_request_friendship_with(user)
    
    # friendship request not possible if they already friends
    assert !user.can_request_friendship_with(friend)
    
    # friendship request possible with a non friend
    assert user.can_request_friendship_with(no_friend)  
  end

  test "friendship exists with" do
    user = users(:users_002)
    friend = users(:users_003)
    no_friend = users(:users_004)
    
    friendship = Friendship.create(
        :friendship_status => FriendshipStatus[:accepted],
        :user => user,
        :friend => friend,
        :initiator => true
    )
    
    assert user.friendship_exists_with?(friend)
    assert !user.friendship_exists_with?(no_friend)
    assert !user.friendship_exists_with?(user)
  end
  
  test "user has_reached_daily_friend_request_limit" do
    current_user = users(:users_002)
    limit = Friendship.daily_request_limit
    
    # create one more dummy user than the daily request limit
    dummies = []
    (1..limit +1).each do |i|
      dummies << create_dummy_user("templogin#{i}")
    end
    
    # request so many friendships so you can do only one last request 
    dummies[0, limit - 1].each do |friend_user|
      Friendship.create(
        :friendship_status => FriendshipStatus[:pending],
        :user => current_user,
        :friend => friend_user,
        :initiator => true
      )
    end
    assert !current_user.has_reached_daily_friend_request_limit?

    # request friendships as much as daily request limit
    Friendship.create(
        :friendship_status => FriendshipStatus[:pending],
        :user => current_user,
        :friend => dummies.last,
        :initiator => true
    )
    assert current_user.has_reached_daily_friend_request_limit?
  end
  
  test "create a private project" do
    user = users(:users_002)
    assert_nil user.private_project
    assert_difference 'Project.count' do
      user.create_private_project
    end
    assert_not_nil user.private_project
  end
  
  test "max length of interest list" do
    user = users(:users_002)
    max_length = 20;
    (1..max_length).each {|i| user.interest_list.push(i.to_s)}
    assert user.valid?
    user.interest_list.push('21')
    assert !user.valid?
    assert !user.errors[:interest_list].empty?
  end
  
  test "max length of skill list" do
    user = users(:users_002)
    max_length = 20;
    (1..max_length).each {|i| user.skill_list.push(i.to_s)}
    assert user.valid?
    user.skill_list.push('21')
    assert !user.valid?
    assert !user.errors[:skill_list].empty?  
  end
  
    
  private
  
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