require File.expand_path('../../../../../test/test_helper', __FILE__)

class AdsControllerTest < ActionController::TestCase
  DUMMY_AD_HTML = "<strong>Buy the new Foo now!</strong>"
  
  fixtures :users

  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
    
    # avoid problems with UserMessage
    UserMessage.destroy_all
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
  
  test "creating a invalid ad redirects to new" do
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    
    # Ad needs more attributes to be valid
    invalid = Ad.new(:html => DUMMY_AD_HTML)

    assert_no_difference 'Ad.count' do    
      post :create, :ad => invalid.attributes
    end
  end
  
  test "create a valid ad as admin redirects to show" do
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    
    ad = create_dummy_ad()

    assert_difference 'Ad.count' do    
      post :create, :ad => ad.attributes
    end
    assert_redirected_to ad_path(assigns(:ad))
  end
  
  test "can't create ad without admin role" do
    # test without login
    ad = create_dummy_ad()
    assert_no_difference 'Ad.count' do
      post :create, :ad => ad.attributes
    end
    
    
    # test with login but not as admin
    normal_user = users(:users_005)
    @request.session[:user_id] = normal_user.id
    assert_no_difference 'Ad.count' do
      post :create, :ad => ad.attributes
    end
  end
  
  private
  def create_dummy_ad
    Ad.new(
      :html => DUMMY_AD_HTML,
      :audience => 'all',
      :frequency => 1
    )
  end
end