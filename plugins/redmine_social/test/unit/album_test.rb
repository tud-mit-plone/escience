require File.expand_path('../../../../../test/test_helper', __FILE__)

class AlbumTest < ActiveSupport::TestCase
  self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"

  fixtures :users, :albums, :photos
  
  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
    fix_fixture_path
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end

  test "load album from fixtures" do
    album = albums(:albums_001)
    #photo = photos(:photos_002)
    assert_equal true, album.valid?
    assert_equal 1, album.photos.count
  end

  test "album must have required fields" do
    album = Album.new
    assert !album.save
    assert !album.errors[:title].empty?
    assert !album.errors[:user_id].empty?
  end
  
  test "album must have user" do
    user = users(:users_002)
    album = create_album(user)
    assert_equal(album.owner, user)
  end

  test "add comment" do
    user = users(:users_002)
    album = create_album(user)
    assert_equal 0, album.comments.count
    comment = Comment.create(:commented => album, :author => user, :comments => "da comment")
    assert comment.save!
    assert_equal 1, album.comments.count
    #album.delete
    #comment.relaod
    #assert_equal nil, comment
  end

  private
  def create_album(user)
    album = Album.create(
      :title => "Album-Title 1",
      )
    album.user = user
    assert album.save!
    return album
  end

  def fix_fixture_path
    ActiveSupport::TestCase.class_eval do
      include ActiveRecord::TestFixtures
      self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"
    end
  end
end