require File.expand_path('../../../../../test/test_helper', __FILE__)

class AppointmentTest < ActiveSupport::TestCase
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

  test "appointment must have required fields" do
    appointment = Appointment.new
    assert !appointment.save
    assert !appointment.errors[:user].empty?
    assert !appointment.errors[:start_date].empty?
    assert !appointment.errors[:subject].empty?
  end

  test "load appointment from fixtures" do
  	appointment = appointments(:appointments_001)
  	assert appointment.valid?
  	user = users(:users_002)
  	assert_equal user, appointment.user
  end

  test "test css_classes" do
  	appointment = appointments(:appointments_001)
  	assert_equal 'appointment', appointment.css_classes
  end

  test "get all events with cycle" do
  	appointments = Appointment.getAllEventsWithCycle(Date.new(2014,11), Date.new(2015,1))
  	assert_equal 7, appointments.count

  	#add appointment with monthly cycle
    user = users(:users_002)
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => Date.new(2014,11), :cycle => 3)
    assert appointment.save!
    appointments = Appointment.getAllEventsWithCycle(Date.new(2014,11), Date.new(2015,1))
  	assert_equal 10, appointments.count
  end

  test "get list of days between start and due" do
    appointments = Appointment.getListOfDaysBetween(Date.new(2014,11), Date.new(2015,1))
    assert_equal 2, appointments.count

    #add appointment without cycle
    #TODO
    user = users(:users_002)
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => Date.new(2014,11), :due_date => Date.new(2014,12), :cycle => 0)
    assert appointment.save!
    appointments = Appointment.getListOfDaysBetween(Date.new(2014,11), Date.new(2015,1))
    assert_not_equal 2, appointments.count
  end

  test "save attributes" do
    #TODO
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
