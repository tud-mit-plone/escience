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
  
  test "only admin can see index" do
    get :index
    assert_response :redirect
    
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    get :index
    assert_response :success
    assert_template :index     
  end

  test "index returns correct search results for name_starts_with" do
    # ensure no other Ads exists
    Ad.destroy_all
    
    # add ads for searching
    ads = [
      create_dummy_ad('aaabbbccccc', 'foo'),
      create_dummy_ad('aafff', 'foo'),
      create_dummy_ad('def', 'foo'),
      create_dummy_ad('aaabcc', 'foo'),
      create_dummy_ad('dbf', 'foo'),
      create_dummy_ad('ccccf', 'foo'),
      create_dummy_ad('bagggg', 'foo')
    ]
    ads.each {|ad| ad.save!}
    
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    get :index, :search => {:name_starts_with => 'aa'}
    
    result = assigns(:search)
    assert result.all.include?(ads[0])
    assert result.all.include?(ads[1])
    assert result.all.include?(ads[3])
    
    assert !result.all.include?(ads[2])
    assert !result.all.include?(ads[4])
    assert !result.all.include?(ads[5])
    assert !result.all.include?(ads[6]) 
  end  
  
  test "index returns correct search results for location_contains" do
    # ensure no other Ads exists
    Ad.destroy_all
    
    # add ads for searching
    ads = [
      create_dummy_ad('one', 'fooaabbccbar'),
      create_dummy_ad('two', 'foogggeeebar'),
      create_dummy_ad('three', 'foocccbar'),
      create_dummy_ad('four', 'fooccbar'),
      create_dummy_ad('five', 'fooddddefffbar'),
      create_dummy_ad('six', 'fooblubccbar'),
      create_dummy_ad('seveb', 'fooffffbar')
    ]
    ads.each {|ad| ad.save!}
    
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    get :index, :search => {:location_contains => 'cc'}
    
    result = assigns(:search)
    assert result.all.include?(ads[0])
    assert result.all.include?(ads[2])
    assert result.all.include?(ads[3])
    assert result.all.include?(ads[5])
    
    assert !result.all.include?(ads[1])
    assert !result.all.include?(ads[4])
    assert !result.all.include?(ads[6]) 
  end
  
  test "pagination works" do
    # ensure no other Ads exists
    Ad.destroy_all
    
    num_ads = 40
    ads = []
    (1..num_ads).each do |i|
      ad = create_dummy_ad(i.to_s, 'foo')
      ad.save!
      ads << ad
    end
    
    per_page = 15
    admin = users(:users_001)
    @request.session[:user_id] = admin.id

    # get page 1
    get :index, :page => 1
    result = assigns(:ads)
    assert_equal per_page, result.all.count
    
    # get page 2
    get :index, :page => 2
    result = assigns(:ads)
    assert_equal per_page, result.all.count
    
    # get page 3
    get :index, :page => 3
    result = assigns(:ads)
    assert_equal num_ads % per_page, result.all.count
  end

  test "creating an invalid ad redirects to new" do
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
  def create_dummy_ad(name = nil, location = nil)
    Ad.new(
      :html => DUMMY_AD_HTML,
      :audience => 'all',
      :frequency => 1,
      :name => name,
      :location => location
    )
  end
end