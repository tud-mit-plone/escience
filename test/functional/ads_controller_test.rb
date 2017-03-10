require File.expand_path('../../test_helper', __FILE__)

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
    # not logged in
    User.current = nil
    get :index
    assert_response :redirect
    
    # normal user logged in
    normal_user = users(:users_002)
    @request.session[:user_id] = normal_user.id
    get :index
    assert_response :forbidden
    
    # admin logged in
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
  
  test "only admin can show ad" do
    ad = create_dummy_ad()
    ad.save!
    
    # not logged in
    User.current = nil
    get :show, :id => ad.id
    assert_response :redirect
    
    # normal user logged in
    normal_user = users(:users_002)
    @request.session[:user_id] = normal_user.id
    get :show, :id => ad.id
    assert_response :forbidden
    
    # admin logged in
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    get :show, :id => ad.id
    assert_response :success
  end
  
  test "show assigns correct ad and renders correct template" do
    ad = create_dummy_ad()
    ad.save!
    
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    
    get :show, :id => ad.id
    assert_response :success
    assert_equal ad.id, assigns(:ad).id
    assert_template :show
  end

  test "only admin can get new ad" do
    # not logged in
    User.current = nil
    get :new
    assert_response :redirect
    
    # normal user logged in
    normal_user = users(:users_002)
    @request.session[:user_id] = normal_user.id
    get :new
    assert_response :forbidden
    
    # admin logged in
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    get :new
    assert_response :success
  end
  
  test "new assigns correct ad and renders correct template" do
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    
    get :new
    assert_response :success
    assert_not_nil assigns(:ad)
    assert_template :new
  end

  test "only admin can get edit ad" do
    ad = create_dummy_ad()
    ad.save!
    
    # not logged in
    User.current = nil
    get :edit, :id => ad.id
    assert_response :redirect
    
    # normal user logged in
    normal_user = users(:users_002)
    @request.session[:user_id] = normal_user.id
    get :edit, :id => ad.id
    assert_response :forbidden
    
    # admin logged in
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    get :edit, :id => ad.id
    assert_response :success
  end
  
  test "edit assigns correct ad and renders correct template" do
    ad = create_dummy_ad()
    ad.save!
    
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    
    get :edit, :id => ad.id
    assert_response :success
    assert_equal ad.id, assigns(:ad).id
    assert_template :edit
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
  
  test "only admin can update ad" do
    ad = create_dummy_ad()
    ad.save!
    
    # not logged in
    User.current = nil
    put :update, :id => ad.id, :ad => {:html => '<p>new html</p>'}
    assert_response :redirect
    
    # normal user logged in
    normal_user = users(:users_002)
    @request.session[:user_id] = normal_user.id
    put :update, :id => ad.id, :ad => {:html => '<p>new html</p>'}
    assert_response :forbidden
    
    # admin logged in
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    put :update, :id => ad.id, :ad => {:html => '<p>new html</p>'}
    assert_redirected_to ad_path(ad)
  end
  
  test "update updates field" do
    ad = create_dummy_ad()
    ad.save!

    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    put :update, :id => ad.id, :ad => {:html => '<p>new html</p>'}
    ad.reload
    assert_equal '<p>new html</p>', ad.html
  end
  
  test "only admin can destroy ad" do
    ad = create_dummy_ad()
    ad.save!
    
    # not logged in
    User.current = nil
    delete :destroy, :id => ad.id
    assert_response :redirect
    
    # normal user logged in
    normal_user = users(:users_002)
    @request.session[:user_id] = normal_user.id
    delete :destroy, :id => ad.id
    assert_response :forbidden
    
    # admin logged in
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    delete :destroy, :id => ad.id
    assert_redirected_to ads_path
  end
  
  test "destroy deletes correct record" do
    ad = create_dummy_ad()
    ad.save!
    
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    
    assert_difference 'Ad.count', -1 do
      delete :destroy, :id => ad.id
    end
    
    assert_equal 0, Ad.where(:id => ad.id).count, 'Ad is deleted'
  end
  
  test "use case create update destroy ad" do
    admin = users(:users_001)
    @request.session[:user_id] = admin.id
    
    # new Ad
    get :new
    ad = assigns(:ad)
    
    # create Ad
    ad.html = '<p>Lorem</p>'
    ad.frequency = 1
    ad.audience = 'all'
    assert_difference 'Ad.count' do
      post :create, :ad => ad.attributes
    end
    assert_not_nil assigns(:ad)
    ad = assigns(:ad)
    assert_redirected_to ad_path(ad)
    
    # follow redirection to show
    get :show, :id => ad.id
    assert_template :show
    assert_equal ad.id, assigns(:ad).id
    ad = assigns(:ad)
    
    # edit Ad
    get :edit, :id => ad.id
    assert_template :edit
    assert_equal ad.id, assigns(:ad).id
    ad.html = '<p>new html</p>'
    ad.name = 'foo'
    ad.location = 'bar'
    
    # update Ad
    put :update, :id => ad.id, :ad => ad.attributes
    assert_equal ad.id, assigns(:ad)
    ad = assigns(:ad)
    assert_redirected_to ad_path(ad)
    assert_equal '<p>new html</p>', ad.html
    
    # destroy Ad
    assert_difference 'Ad.count', -1 do
      delete :destroy, :id => ad.id
    end
    assert_redirected_to ads_path
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