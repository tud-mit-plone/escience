require File.expand_path('../../../../../test/test_helper', __FILE__)
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerExtensionTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :users, :projects, :members, :member_roles, :roles,
           :custom_fields, :custom_values, :groups_users,
           :auth_sources
  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
                           [:photos])

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
  
  # isn't testable because there is a bug in the view connected with this method
  # test "upload profile photo" do
    # user = users(:users_002)
    # @request.session[:user_id] = user.id
    # photo = Photo.find(1)
#     
    # put :upload_profile_photo, :id => user.id, :photo => photo.attributes
  # end
  
  test "crop profile photo" do
    user = users(:users_002)
    @request.session[:user_id] = user.id
    photo = Photo.find(1)
    put :crop_profile_photo, :id => user.id, :photo => photo.attributes
    assert_response :redirect
    assert_redirected_to my_account_path
  end
  
  test "tag search" do
    begin
      admin = users(:users_001)
      user = users(:users_002)
      @request.session[:user_id] = admin.id
      
      # no route defined for action tag_search
      # we have to define it at manually
      Rails.application.routes.draw { get 'tag_search' => 'users#tag_search' }

      # word from taglist
      get :tag_search, :q => 'administration', :format => :xml
      assert_response :success
      assert_select "acts-as-taggable-on-tag", 1
      assert_select "name", {count: 1, text: "administration"}
      assert_select "taggings-count", {count: 1, text: "2"}
      
      # word not in taglist
      get :tag_search, :q => 'not_in_list', :format => :xml
      assert_response :success
      assert_select "acts-as-taggable-on-tag", 0
      assert_select "nil-classes", 1
    ensure
      # restore routes
      Rails.application.reload_routes!
    end
  end
  
  test "update method for creating a private project" do
    admin = users(:users_001)
    user = users(:users_002)   
    # admin login required
    @request.session[:user_id] = admin.id
    
    private_project_before = user.private_project
    assert_difference 'Project.count' do
      put :update, :id => user.id,
          :user => {:firstname => 'Changed', :mail_notification => 'only_assigned'},
          :pref => {:hide_mail => '1', :comments_sorting => 'desc'}   
    end
    #reload user to refresh the user attributes
    user.reload
    private_project_after = user.private_project
    assert_not_equal private_project_before, private_project_after
  end
  
  test "contact member search" do
    user = users(:users_002)
    contact_member = users(:users_003)

    get :contact_member_search, :q => contact_member.lastname, :format => :json
    assert_response 401  
    
    #user login required
    @request.session[:user_id] = user.id
    #contact member have to be searchable
    contact_member.security_number = User.searchable_sql
    contact_member.confirm = true
    contact_member.save!
    
    get :contact_member_search, :q => contact_member.lastname, :format => :json
    assert_response :success

    body = json_response
    project = body.first
    project_hash = project.last
    role = project_hash.first
    found_user = role.last
    
    firstname = found_user[0]["user"]["firstname"]
    lastname = found_user[0]["user"]["lastname"]
    
    assert_equal contact_member.firstname, firstname
    assert_equal contact_member.lastname, lastname
  end
  
  # # this method is already tested through 'show'-method-test
  # test "require user security" do
    # admin = users(:users_001)
    # user_1 = users(:users_002)
    # user_2 = users(:users_003) 
#     
    # # 1. case: logged in user is the same user for request
    # # @request.session[:user_id] = user_1.id  
    # # @controller.require_user_security(user_1.id)
# 
    # # 2. case: account have to be readable for user
    # user_2.security_number = User.account_readable_for_user
    # user_2.confirm = true
    # user_2.save!
    # assert @controller.require_user_security(user_2.id)
#     
    # # 3. case: admin is logged in
    # # @request.session[:user_id] = admin.id 
    # # assert @controller.require_user_security(user_1.id)
  # end 
  
  test "require user security through show method" do
    admin = users(:users_001)
    user_1 = users(:users_002)
    user_2 = users(:users_003)
    
    # 1. case: logged in user is the same user for request
    @request.session[:user_id] = user_1.id  
    # get :show, :id => user_1.id
    # assert_response :success

    # 2. case: account is readable for user
    user_2.security_number = User.account_readable_for_user
    user_2.confirm = true
    user_2.save!
    get :show, :id => user_2.id
    assert_response :success
    
    # 3. case: admin is logged in
    @request.session[:user_id] = admin.id 
    get :show, :id => user_1.id
    assert_response :success
  end 
  
  
  private
  
  def json_response
    ActiveSupport::JSON.decode @response.body
  end
end