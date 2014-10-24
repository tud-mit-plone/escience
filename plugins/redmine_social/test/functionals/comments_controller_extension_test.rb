require File.expand_path('../../../../../test/test_helper', __FILE__)

class CommentsControllerExtensionTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules, :news, :comments
  
  #fixtures aus dem plugin-test-ordner laden
  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
                            [:albums])
  
  def setup
    # before_filter 'authorize' must be disable in comments_controller.rb and
    # patch_comment.rb while 'create_general_comment' method is not set in the
    # allowed actions in project.rb    
    
    # broken naming convention: controller can't infer from TestCase name
    # needed for tests for CommentsController
    @controller = CommentsController.new
    
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
  
  test "create comment for news" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id

    news = news(:news_003)
    
    # ensure no comments exist for news
    Comment.destroy_all
    
    assert_difference 'news.comments.count' do
      post :create_general_comment, :news_id => news.id, :id => news.id, :comment => { :comments => 'This is a test comment for news' }
    end
    assert_redirected_to news_path(news)
    
    comment = news.comments.last
    assert_not_nil comment
    assert_equal 'This is a test comment for news', comment.comments
    assert_equal user_1, comment.author 
  end
  
  test "create comment for album" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id

    #album = albums(:albums_003)
    album = Album.find_by_id(1)
    
    # ensure no comments exist for news
    Comment.destroy_all
    
    assert_difference 'album.comments.count' do
      post :create_general_comment, :album_id => album.id, :id => album.id, :comment => { :comments => 'This is a test comment for album' }
    end
    assert_redirected_to album_path(album)
    
    comment = album.comments.last
    assert_not_nil comment
    assert_equal 'This is a test comment for album', comment.comments
    assert_equal user_1, comment.author 
  end
  
  
  test "create comment for photo" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id

    #photo = photos(:photos_001)
    photo = Photo.find_by_id(1)
    
    # ensure no comments exist for news
    Comment.destroy_all
    
    assert_difference 'photo.comments.count' do
      post :create_general_comment, :photo_id => photo.id, :id => photo.id, :comment => { :comments => 'This is a test comment for photo' }
    end
    assert_redirected_to photo_path(photo)
    
    comment = photo.comments.last
    assert_not_nil comment
    assert_equal 'This is a test comment for photo', comment.comments
    assert_equal user_1, comment.author 
  end
  
  test "empty comment should not be added for news" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id
    
    news = news(:news_003)
    
    assert_no_difference 'Comment.count' do
      post :create_general_comment, :news_id => news.id, :id => news.id, :comment => { :comments => '' }
      assert_response :redirect
      assert_redirected_to news_path(news)
    end
  end
  
  test "empty comment should not be added for album" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id
    
    #album = albums(:albums_003)
    album = Album.find_by_id(1)
    
    assert_no_difference 'Comment.count' do
      post :create_general_comment, :album_id => album.id, :id => album.id, :comment => { :comments => '' }
      assert_response :redirect
      assert_redirected_to album_path(album)
    end
  end
  
  test "empty comment should not be added for photo" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id
    
    #photo = photos(:photos_001)
    photo = Photo.find_by_id(1)
    
    assert_no_difference 'Comment.count' do
      post :create_general_comment, :photo_id => photo.id, :id => photo.id, :comment => { :comments => '' }
      assert_response :redirect
      assert_redirected_to photo_path(photo)
    end
  end
  
  # test "create should be denied if news is not commentable" do
    # News.any_instance.stubs(:commentable?).returns(false)
#     
    # user_1 = users(:users_002)
    # @request.session[:user_id] = user_1.id
#     
    # news = news(:news_003)
#     
    # assert_no_difference 'Comment.count' do
      # post :create_general_comment, :news_id => news.id, :id => news.id, :comment => { :comments => 'This is a test comment for news' }
      # assert_response 403
    # end
  # end
end