require File.expand_path('../../../../../test/test_helper', __FILE__)

class AlbumTest < ActiveSupport::TestCase
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
    comment = Comment.new(:commented => album, :author => user, :comments => "da comment")
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
      :user => user
      #:user_id => user.id
      )
    #album.user = user
    assert album.save!
    return album
  end
end