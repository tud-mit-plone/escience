require File.expand_path('../../../../../test/test_helper', __FILE__)

class GroupInvitationControllerTest < ActionController::TestCase

  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
  
end