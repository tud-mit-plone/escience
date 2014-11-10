require File.expand_path('../../../../../test/test_helper', __FILE__)

class AppointmentsControllerTest < ActionController::TestCase
  self.fixture_path = "#{Rails.root}/plugins/redmine_appointments/test/fixtures/"

  fixtures :users, :appointments
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

  test "filter find appointment" do

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