require File.expand_path('../../../../../test/test_helper', __FILE__)
require 'my_controller'

# Re-raise errors caught by the controller.
class MyController; def rescue_action(e) raise e end; end

class MyControllerExtensionTest < ActionController::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
  :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :auth_sources
  
  def setup
    # broken naming convention: controller can't infer from TestCase name
    # needed for tests for MyController
    @controller = MyController.new
    @request    = ActionController::TestRequest.new
    @user = users(:users_002)
    @request.session[:user_id] = @user
    @response   = ActionController::TestResponse.new
    
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
   
   
  test "interest search" do
    word_syllable = "admini"
    get :interest_search, :q => word_syllable, :format => :json
    assert_response :success
    interests = json_response
    tag_names = get_tag_names(interests)
    assert tag_names.include?('administration')
  end
  
  test "skill search" do
    word_syllable = "progra"
    get :skill_search, :q => word_syllable, :format => :json
    assert_response :success
    skills = json_response
    tag_names = get_tag_names(skills)
    assert tag_names.include?('programming')
  end
   
  test "prepare tag params" do
    my_controller_dummy = MyController.new
    example_tag_string = 'Soccer, Computer, TV'
    prepared_tag_list = my_controller_dummy.prepare_tag_params(example_tag_string)

    assert_equal prepared_tag_list.count, 3
    assert_equal "Soccer", prepared_tag_list[0]
    assert_equal "Computer", prepared_tag_list[1]
    assert_equal "TV", prepared_tag_list[2]     
  end
  
  # test "redirect to index if render block has no blockname attribut" do
    # uid = @user.id
    # get :render_block, :blockname => nil
    # assert_redirected_to '/my?user_id='+uid.to_s
  # end
  
  test "update account" do
    user = users(:users_002)
    
    # ensure user has a private project
    user.create_private_project
    
    # ensure user has accepted Terms & Privacy
    #user.confirm = true

    user_hash = user.attributes
    user_hash[:firstname] = 'Joe'

    post :account,
      :user => user_hash,
      :pref => {:hide_mail => false},
      :my_interest => 'Soccer, Computer',
      :my_skill => 'Java, Testing',
      :enabled_module_names => ['time_tracking']
    
    assert_redirected_to my_account_path(:sub => 'my_account')

    #reload user to refresh the user attributes
    user.reload

    assert_equal user, assigns(:user)
    assert_equal "Joe", user.firstname
    assert_equal "Soccer", user.interest_list[0]
    assert_equal "Computer", user.interest_list[1]
    assert_equal "Java", user.skill_list[0]
    assert_equal "Testing", user.skill_list[1]
    assert_equal "time_tracking", user.private_project.enabled_module_names.first
  end
  
  
  
  private
  
  def json_response
    ActiveSupport::JSON.decode @response.body
  end
  
  def get_tag_names(tags)
    tags.collect {|entry| entry["tag"]["name"]}
  end
end