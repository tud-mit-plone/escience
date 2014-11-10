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

  test "filter find_appointment" do
    #wrong appointment id
    get :show, :id => 1000050
    assert_response :missing

    #appointment is public
    appointment = appointments(:appointments_001)
    get :show, :id => appointment.id
    assert_response :success
    assert_template :show
  end

  test "filter find_appointment with private appointment" do
    #appointment is private
    user = users(:users_002)
    appointment1 = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => Date.new(2014,11), :is_private => true, :cycle => 0)
    assert appointment1.save!
    get :show, :id => appointment1.id
    assert_response :redirect

    #user is logged in
    @request.session[:user_id] = user.id
    User.current = user
    get :show, :id => appointment1.id
    assert_response :success
    assert_template :show
  end

  test "test show if cycle not set" do
    #TODO
  end

  test "index" do
    get :index
    assert_response :success
    assert_template :index
  end

  test "create appointment" do
    #post :create
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