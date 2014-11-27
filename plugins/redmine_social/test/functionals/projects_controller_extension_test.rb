require File.expand_path('../../../../../test/test_helper', __FILE__)

class ProjectsControllerExtensionTest < ActionController::TestCase

  fixtures :users, :projects

  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    #@response   = ActionController::TestResponse.new
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
  
  test "filter no_private_project" do
    user = users(:users_003)
    @request.session[:user_id] = user
    #Project is not public
    project = Project.find(2)

    assert !project.users.include?(user)
    get :show, :id => project.id
    assert_response(403)

    #Project is public
    project = Project.find(3)    
    get :show, :id => project.id
    assert_response :success
    assert_template :show
  end

end
