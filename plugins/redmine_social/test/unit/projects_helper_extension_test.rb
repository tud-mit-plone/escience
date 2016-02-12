require File.expand_path('../../../../../test/test_helper', __FILE__)

class ProjectHelperExtensionTest < ActiveSupport::TestCase
  fixtures :users, :members, :projects

  include ActionView::Helpers::AssetTagHelper
  #include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ProjectsHelper

  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end

  test "test private_project_settings_tabs" do
    project = Project.find(2)
    assert_equal [{:name=>"modules", :action=>:select_project_modules, :partial=>"projects/settings/modules", :label=>:label_module_plural},
    {:name=>"repositories", :action=>:manage_repository, :partial=>"projects/settings/repositories", :label=>:label_repository_plural},
    {:name=>"activities", :action=>:manage_project_activities, :partial=>"projects/settings/activities", :label=>:enumeration_activities},
    {:name=>"wiki", :action=>:manage_wiki, :partial=>"projects/settings/wiki", :label=>:label_wiki}],
    private_project_settings_tabs(project)
  end


end