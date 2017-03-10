require File.expand_path('../../test_helper', __FILE__)

class PhotosControllerTest < ActionController::TestCase
  self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"

  fixtures :users, :photos

#ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
#                            [:photos])

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

  test "show index" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    #photo = current_user.photos.last
    get :index, :user_id => current_user.id
    assert_response :success
    assert_template :index
    assert_equal current_user.photos.count, assigns(:photos).count
  end

  test "destroy users photo if logged in" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    photo = current_user.photos.last
    assert_difference 'current_user.photos.count', -1 do
      delete :destroy, :user_id => current_user.id, :id => photo.id
    end
    assert_redirected_to user_photos_path(current_user)
  end

  test "destroy users photo if not logged in" do
    User.current = nil
    user = users(:users_002)
    photo = user.photos.last
    assert_difference 'user.photos.count', 0 do
      delete :destroy, :user_id => user.id, :id => photo.id
    end
    #assert_redirected_to :back
    assert_redirected_to '/?back_url=http%3A%2F%2Ftest.host%2Fusers%2F2%2Fphotos%2F2'
  end

  test "destroy users photo if logged as wrong user" do
    User.current = nil
    @request.session[:user_id] = users(:users_003)
    user = users(:users_002)
    photo = user.photos.last
    assert_difference 'user.photos.count', 0 do
      delete :destroy, :user_id => user.id, :id => photo.id
    end
  end

  test "create users photo if logged in" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    assert_difference 'current_user.photos.count' do
      post :create, :photo =>{:photo => uploaded_test_file("101123161450_testfile_1.png", "image/png")}
    end
    assert_equal @controller.l(:photo_was_successfully_created), flash[:notice]
    assert_redirected_to user_photo_path(current_user, assigns(:photo).id)
    #puts @response.body
  end

  test "create not valid photo" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    photo = Photo.new
    assert_difference 'current_user.photos.count', 0 do
      post :create, :photo => photo
    end
  end

  test "update description of Photo" do
    description = "Das ist ein Test"
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    photo = current_user.photos.last
    put :update, :id => photo.id, :photo =>{:description => description}
    assert_redirected_to user_photo_path(current_user, assigns(:photo).id)
    assert_equal description , assigns(:photo).description
  end

  test "update description of Photo as wrong user" do
    @request.session[:user_id] = users(:users_005)
    description = "Das ist ein Test"
    user = users(:users_002)
    photo = user.photos.last
    put :update, :id => photo.id, :photo =>{:description => description}
    assert_not_equal description, photo.description 
    assert_redirected_to '/?back_url=http%3A%2F%2Ftest.host%2Fphotos%2F2'
  end

  test "respond to show photo if logged in" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    photo = create_photo(current_user, "101123161450_testfile_1.png", "image/png")
    get :show, :id => photo.id
    assert_response :success
    assert_template :show
    assert_equal photo, assigns(:photo)
  end
  
  test "respond to show photo if not logged in" do
    user = users(:users_002)
    photo = create_photo(user, "101123161450_testfile_1.png", "image/png")
    get :show, :id => photo.id
    assert_equal @controller.l(:please_log_in), flash[:error]
    assert_response :redirect
  end

  test "add comment to photo if logged in" do
    current_user = users(:users_002)
    photo = create_photo(current_user, "101123161450_testfile_1.png", "image/png")
    photo = current_user.photos[0]
    @request.session[:user_id] = current_user.id
    assert_difference 'photo.comments.count' do 
      post :add_comment, :photo_id => photo.id, :comment => {:comments => 'Test-Comment'} 
    end
    assert_equal 'Test-Comment', assigns(:comment).comments
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

  # Because a bug, a overriden fixture_path method get not called for files,
  # so we have to set the variable manually.
  # https://github.com/rspec/rspec-rails/issues/252#issuecomment-1438267
  def fix_fixture_path
    ActiveSupport::TestCase.class_eval do
      include ActiveRecord::TestFixtures
      self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"
    end
  end

end