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

  test "test create users photo if logged in" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    assert_difference 'current_user.photos.count' do
      post :create, :photo =>{:photo => uploaded_test_file("101123161450_testfile_1.png", "image/png")}
    end
    assert_equal @controller.l(:photo_was_successfully_created), flash[:notice]
    assert_redirected_to user_photo_path(current_user, assigns(:photo).id)
    #assert_select "page", {count: 1, text: ""}
    #assert_select "alert", "elcome"
  end

  test "respond to show photo if logged in" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    photo = create_photo(current_user, "101123161450_testfile_1.png", "image/png")
    get :show, :id => photo.id
    assert_response :success
    assert_equal photo, assigns(:photo)
  end
  
  test "add comment to photo if logged in" do
    current_user = users(:users_002)
    photo = create_photo(current_user, "101123161450_testfile_1.png", "image/png")
    photo = current_user.photos[0]
    @request.session[:user_id] = current_user.id
    assert_difference 'photo.comments.count' do 
      post :add_comment, :photo_id => photo.id, :comment => {:comments => 'Test-Comment'} 
    end
    comments_count = photo.comments.count
    assert_equal 'Test-Comment', current_user.photos[0].comments[comments_count - 1].comments
    assert_redirected_to user_photo_path(current_user, photo)
  end

  test "add comment to photo as anonym user" do
    user = users(:users_002)
    @request.session[:user_id] = nil
    photo = create_photo(user, "101223161450_testfile_2.png", "image/png")
    assert_difference 'photo.comments.count' do 
      post :add_comment, :photo_id => photo.id, :comment => {:comments => 'Test-Comment'} 
    end
    assert_equal User.anonymous, photo.comments.last.author
    assert_redirected_to user_photo_path(user, photo)
  end


  private
  def create_photo(user, file, type)
    file = uploaded_test_file(file, type)
    if File.exist?(file)
      photo = Photo.create()
      photo.user_id = user.id
      photo.photo = file
      photo.save!
      return photo
    else
      return nil
    end
  end

end