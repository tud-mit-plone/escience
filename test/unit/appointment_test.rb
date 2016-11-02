require File.expand_path('../../test_helper', __FILE__)

class AppointmentTest < ActiveSupport::TestCase
  fixtures :users, :appointments

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

  test "get all events with resolved_cycles" do
  	appointments = Appointment.getAllEventsWithResolvedCycles(Appointment, DateTime.new(2014,11), DateTime.new(2015,1))
  	assert_equal 7, appointments.count

  	#add appointment with monthly cycle
    user = users(:users_002)
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => DateTime.new(2014,11), :cycle => Appointment::CYCLE_MONTHLY)
    assert appointment.save!
    appointments = Appointment.getAllEventsWithResolvedCycles(Appointment, DateTime.new(2014,11), DateTime.new(2015,1))
  	assert_equal 10, appointments.count
  end

  test "appointment visible?" do
    #appointment is public
    user = users(:users_002)
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => DateTime.new(2014,11), :due_date => DateTime.new(2014,12), :cycle => 0)
    assert appointment.visible?

    #appointment ist privat
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => DateTime.new(2014,11), :due_date => DateTime.new(2014,12), :cycle => 0, :is_private => true)
    assert !appointment.visible?

    assert appointment.visible?(user)

  end

  test "appointment clone" do
    user = users(:users_002)
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => DateTime.new(2014,11), :due_date => DateTime.new(2014,12), :cycle => 0)
    appointment1 = appointment.clone
    assert_equal appointment1, appointment
  end

  test "save attributes" do
    user = users(:users_002)
    User.current = user
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => DateTime.new(2014,11), :cycle => 3)
    assert appointment.save!
    appointment.safe_attributes = {"cycle" => 1}
    assert_equal 1, appointment.cycle
  end

end
