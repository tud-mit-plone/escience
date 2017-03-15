require File.expand_path('../../test_helper', __FILE__)

class AppointmentsControllerTest < ActionController::TestCase

  fixtures :users, :appointments
  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end

  test "filter find_appointment" do
    user = users(:users_002)
    @request.session[:user_id] = user.id
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
    #Anonym user
    user = users(:users_002)
    appointment1 = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => Date.new(2014,11), :is_private => true, :cycle => 0)
    assert appointment1.save!
    get :show, :id => appointment1.id
    assert_response :redirect

    #wrong user
    @request.session[:user_id] = users(:users_003)
    appointment1 = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => Date.new(2014,11), :is_private => true, :cycle => 0)
    assert appointment1.save!
    get :show, :id => appointment1.id
    assert_response :forbidden

    #user is logged in
    @request.session[:user_id] = user.id
    User.current = user
    get :show, :id => appointment1.id
    assert_response :success
    assert_template :show
  end

  test "test show if cycle not set" do
    user = users(:users_002)
    @request.session[:user_id] = user.id
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => Date.new(2014,11))
    get :show, :id => appointment.id
    assert_response :success
    assert_template :show
  end

  test "index" do
    user = users(:users_002)
    @request.session[:user_id] = user.id
    get :index
    assert_response :success
    assert_template :index
  end

  test "create appointment if logged in" do
    user = users(:users_002)
    @request.session[:user_id] = user.id
    post :create, :appointment =>{:subject => 'test',
      :start_date => '11/01/2014', :start_time => Time.new.strftime("%H:%M:%S"),
      :due_date => '11/02/2014', :due_time => Time.new.strftime("%H:%M:%S")}
    assert_redirected_to appointment_path(assigns(:appointment).id)
    assert_equal @controller.l(:notice_appointment_successful_create), flash[:notice]
    assert_equal user.id, assigns(:appointment).author_id

    #Wieviele werden nach dem create angezeigt? Seite wird nicht neugeladen(?)
  end

  test "create not valid appointment" do
    user = users(:users_002)
    @request.session[:user_id] = user.id
    #start_date is after due_date
    post :create, :appointment =>{:subject => 'test',
      :start_date => '12/01/2014', :start_time => Time.new.strftime("%H:%M:%S"),
      :due_date => '11/01/2014', :due_time => Time.new.strftime("%H:%M:%S")}
    assert_response :success
    assert_template :new
    assert flash[:error]
  end

  test "update appointment-cycle if logged in" do
    user = users(:users_002)
    @request.session[:user_id] = user.id
    appointment = appointments(:appointments_001)
    put :update, :id => appointment.id, :appointment =>{:subject => 'test',
      :start_date => '11/14/2014', :start_time => '16:35:38',
      :due_date => '12/14/2014', :due_time => '16:35:38', :cycle => 1}
    assert_equal 1, assigns(:appointment).cycle
  end

  test "update public appointment as other user" do
    #user = users(:users_002)
    current_user = users(:users_003)
    @request.session[:user_id] = current_user.id
    appointment = appointments(:appointments_001)
    put :update, :id => appointment.id, :appointment =>{:subject => 'test',
      :start_date => '11/14/2014', :start_time => '16:35:38',
      :due_date => '12/14/2014', :due_time => '16:35:38', :cycle => 1}
    appointment.reload
    assert_not_equal 1, appointment.cycle
  end

  test "destroy appointment if logged in" do
    assert_difference "Appointment.count", -1 do
      user = users(:users_003)
      @request.session[:user_id] = user.id
      appointment = appointments(:appointments_003)
      delete :destroy, :id => appointment.id
    end
  end

  test "destroy private appointment as wrong user" do
    user = users(:users_002)
    appointment = Appointment.create(:author_id => user.id, :subject => 'test',
      :start_date => Date.new(2014,11), :is_private => true, :cycle => 0)
    assert appointment.save!
    
    current_user = users(:users_003)
    @request.session[:user_id] = current_user
    assert_no_difference 'Appointment.count' do
      delete :destroy, :id => appointment.id
    end
  end

end
