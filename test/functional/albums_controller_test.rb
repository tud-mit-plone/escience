require File.expand_path('../../test_helper', __FILE__)

class AlbumsControllerTest < ActionController::TestCase
	self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"

	fixtures :users, :albums, :photos, :comments

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

 	test "filter require current user with wrong user" do
    current_user = users(:users_003)
    @request.session[:user_id] = current_user.id
    album = albums(:albums_001)
    post :create, :user_id => album.user_id
    assert_response :redirect
    #assert_redirected_to "/?back_url=http%3A%2F%2Ftest.host%2Fusers%2F1063308490%2Falbums"
  end

  test "filter require login if not logged in" do
    album = albums(:albums_001)
    get :show, id: album.id
    assert_response :redirect
    #assert_redirected_to "/?back_url=http%3A%2F%2Ftest.host%2Falbums%2F1"
  end

  test "show album" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    album = albums(:albums_001)
    assert_equal current_user.id, album.user_id
    get :show, :id => album.id
    assert_response :success
    assert_template :show
  end

  #Error in view/albums/show.html.erb:29
  test "show album with no description" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    album = Album.new
    album.user_id = current_user.id
    album.title = "Test"
    assert album.valid?
    assert album.save
    get :show, :id => album.id
    assert_response :success
    assert_template :show
  end

  #Problem with Project and with hash :album_id, albums_controller:49
  test "create album" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    assert_difference 'current_user.albums.count' do
      post :create, :user_id => current_user.id, :album => {:user_id => current_user.id,
        :title => "Test-Title", :description => "Test-Description"}, :commit => 'only_create'
    end
    assert_redirected_to edit_user_album_path(current_user.id, assigns(:album).id)
    assert_equal current_user.albums.last, assigns(:album)
  end

	test "index" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    album = albums(:albums_001)
    #Problem with container, albums_container:129
    get :index, :id => album.id
    assert_response :success
    assert_template :index

    #show index if user has no album
    current_user = users(:users_004)
    @request.session[:user_id] = current_user.id
    get :index
    assert_redirected_to new_album_path
	end

  test "update album" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    album = albums(:albums_001)
    put :update, :user_id => current_user.id, :id => album.id, :go_to => 'only_create',:album => {:description => "Blub"}
    assert_redirected_to edit_user_album_path(current_user.id, album.id)
    assert_equal @controller.l(:album_updated), flash[:notice]
    assert_equal "Blub", assigns(:album).description
  end

  test "delete album" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    album = albums(:albums_001)
    assert_difference 'current_user.albums.count', -1 do
      delete :destroy, :user_id => current_user.id, :id => album.id
    end
    assert_redirected_to user_albums_path
  end

  test "add photo to album" do
    current_user = users(:users_002)
    @request.session[:user_id] = current_user.id
    album = albums(:albums_001)
    put :update, :user_id => current_user.id, :id => album.id
    assert_redirected_to new_user_album_photo_path(current_user.id, album.id)
  end

	private
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
