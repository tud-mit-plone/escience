require File.expand_path('../../../../../test/test_helper', __FILE__)

class FriendshipTest < ActiveSupport::TestCase
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
  
  test "friendship must have required fields" do
    friendship = Friendship.new
    assert !friendship.save
    assert !friendship.errors[:friendship_status].empty?
    assert !friendship.errors[:user].empty?
    assert !friendship.errors[:friend].empty?    
  end
  
  test "reverse returns corresponding friendship" do
    friendship = Friendship.create(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_002),
      :friend => users(:users_003),
      :initiator => true
    )
    
    # Create reverse. Is normaly done by FriendshipController#create.
    Friendship.create(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_003),
      :friend => users(:users_002),
      :initiator => false
    )
    
    reverse = friendship.reverse
    assert_not_nil reverse
    assert_equal friendship.friendship_status, reverse.friendship_status
    assert_equal friendship.friend, reverse.user
    assert_equal friendship.user, reverse.friend
  end
  
  test "friends? returns true if a friendship is accepted" do
    friendship = Friendship.create(
      :friendship_status => FriendshipStatus[:accepted],
      :user => users(:users_002),
      :friend => users(:users_003),
      :initiator => true
    )
    #corresponding reverse friendship
    Friendship.create(
      :friendship_status => FriendshipStatus[:accepted],
      :user => users(:users_003),
      :friend => users(:users_002),
      :initiator => false
    )
    
    assert Friendship.friends? users(:users_002), users(:users_003)
    assert Friendship.friends? users(:users_003), users(:users_002)
  end
  
  test "friends? returns false if a friendship not exists or is not accepted" do
    assert !(Friendship.friends? users(:users_002), users(:users_003))
    assert !(Friendship.friends? users(:users_003), users(:users_002))
    
    friendship = Friendship.create(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_002),
      :friend => users(:users_003),
      :initiator => true
    )
    #corresponding reverse friendship
    Friendship.create(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_003),
      :friend => users(:users_002),
      :initiator => false
    )
    
    assert !(Friendship.friends? users(:users_002), users(:users_003))
    assert !(Friendship.friends? users(:users_003), users(:users_002))
  end
  
  test "friendship cannot create for the same user" do
    friendship = Friendship.new(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_002),
      :friend => users(:users_002),
      :initiator => true
    )
    assert !friendship.save
    assert friendship.errors.full_messages.any? do |msg|
      msg.casecmp("can not be same as friend") == 0
    end
  end
  
  test "friendship must be unique" do
    friendship = Friendship.create(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_002),
      :friend => users(:users_003),
      :initiator => true
    )
    duplicate = Friendship.new(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_002),
      :friend => users(:users_003),
      :initiator => true
    )
    
    assert !duplicate.save
    assert duplicate.errors.full_messages.any? do |msg|
      msg.casecmp("has allready been taken") == 0
    end
  end
  
  test "corresponding friendships can't be both initiators" do
    friendship = Friendship.create(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_002),
      :friend => users(:users_003),
      :initiator => true
    )
    reverse = Friendship.new(
      :friendship_status => FriendshipStatus[:pending],
      :user => users(:users_003),
      :friend => users(:users_002),
      :initiator => true
    )
    
    assert !reverse.save
    assert !reverse.errors[:initiator].empty?
  end
  
  test "friendship can't create after exceeding daily request limit" do
    current_user = users(:users_002)
    limit = Friendship.daily_request_limit
    
    # create one more dummy user than the daily request limit
    dummies = []
    (1..limit + 1).each do |i|
      dummies << create_dummy_user("templogin#{i}")
    end
    
    # request friendships as much as daily request limit
    dummies[0, limit].each do |friend_user|
      Friendship.create(
        :friendship_status => FriendshipStatus[:pending],
        :user => current_user,
        :friend => friend_user,
        :initiator => true
      )
    end
    
    too_much = Friendship.new(
      :friendship_status => FriendshipStatus[:pending],
      :user => current_user,
      :friend => dummies.last,
      :initiator => true
    )
    assert !too_much.save
    assert too_much.errors.full_messages.any? do |msg|
      msg.casecmp("sorry, you'll have to wait a little while before requesting any more friendships.") == 0
    end
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