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

  test "test create users photo" do
    # current_user = users(:users_002)
    # #index muss aufgerufen werden, weil ansonsten user nicht belegt ist
    # get :index, :user_id => current_user.id, format: "html"
    # file = uploaded_test_file("101123161450_testfile_1.png", "image/png")
    # assert_difference 'current_user.photos.count' do
    #   post :create, :user_id => current_user.id, :photo => file
    # end
    # assert_redirected_to user_photos_path
  end

  #TODO Funktioniert nicht, weil nicht eingeloggt
  test "respond to show photo if logged in" do
    current_user = users(:users_002)
    # @request.session[:user_id] = current_user.id
    get :index, :user_id => current_user.id
    photo = create_photo(current_user, "101123161450_testfile_1.png", "image/png")
    post :show, :user_id => current_user.id, :id => photo.id
    assert_redirected_to user_photo_url(photo)
  end
  
  test "add comment to photo if logged in" do
    current_user = users(:users_002)
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
      #photo.comments = []
      photo.save!
      return photo
    else
      return nil
    end
  end

end