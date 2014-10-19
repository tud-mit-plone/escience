require File.expand_path('../../../../../test/test_helper', __FILE__)

class PhotosControllerTest < ActionController::TestCase
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
  
  test "add comment if logged in" do
    current_user = users(:users_002)
    photo = current_user.photos[0]
    comments_count = photo.comments.count
    @request.session[:user_id] = current_user.id
    post :add_comment, :photo_id => photo.id, :comment => {:comments => 'Test-Comment'}
    assert_equal comments_count + 1, current_user.photos[0].comments.count
    assert_equal 'Test-Comment', current_user.photos[0].comments[comments_count].comments
  end

  test "add comment anonym" do
    user = users(:users_003)
    photo = create_photo(user, "101123161450_testfile_1.png", "image/png")
    comments_count = photo.comments.count
    post :add_comment, :photo_id => photo.id, :comment => {:comments => 'Test-Comment'}
    comment = photo.comments.last
    assert_equal comments_count  + 1, photo.comments.count
    assert_equal User.anonymous, comment.author
  end


  private
  def create_photo(user, file, type)
    file = uploaded_test_file(file, type)
    if File.exist?(file)
      photo = Photo.new
      photo.user = user
      photo.photo = file
      photo.save!
      return photo
    else
      return nil
    end
  end

end