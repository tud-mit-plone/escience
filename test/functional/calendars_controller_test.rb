require File.expand_path('../../test_helper', __FILE__)

class CalendarsControllerTest < ActionController::TestCase
  fixtures :projects,
           :trackers,
           :projects_trackers,
           :roles,
           :member_roles,
           :members,
           :enabled_modules

  def setup
    @request.session[:user_id] = 2
  end

  def test_calendar
    get :show, :project_id => 1
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end

  def test_cross_project_calendar
    get :show
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end

  def  test_run_custom_queries
    @query = Query.create!(:name => 'Calendar', :is_public => true)
    get :show, :query_id => @query.id
    assert_response :success
  end

  def test_week_number_calculation
    Setting.start_of_week = 7

    get :show, :month => '1', :year => '2010'
    assert_response :success

    assert_tag :tag => 'tr',
               :descendant => {:tag => 'td',
                               :attributes => {:class => 'week-number'},
                               :child => {:tag => 'td', :content => 53},},
               :descendant => {:tag => 'p',
                               :attributes => {:class => 'day-num'}, :content => '27'},
               :descendant => {:tag => 'p',
                               :attributes => {:class => 'day-num'}, :content => '2'}

    assert_tag :tag => 'tr',
               :descendant => {:tag => 'td',
                               :attributes => {:class => 'week-number'},
                               :child => {:tag => 'td', :content => 53},},
               :descendant => {:tag => 'p',
                               :attributes => {:class => 'day-num'}, :content => '3'},
               :descendant => {:tag => 'p',
                               :attributes => {:class => 'day-num'}, :content => '9'}


    Setting.start_of_week = 1
    get :show, :month => '1', :year => '2010'
    assert_response :success

    assert_tag :tag => 'tr',
               :descendant => {:tag => 'td',
                               :attributes => {:class => 'week-number'},
                               :child => {:tag => 'td', :content => 53},},
               :descendant => {:tag => 'p',
                               :attributes => {:class => 'day-num'}, :content => '28'},
               :descendant => {:tag => 'p',
                               :attributes => {:class => 'day-num'}, :content => '3'}

    assert_tag :tag => 'tr',
               :descendant => {:tag => 'td',
                               :attributes => {:class => 'week-number'},
                               :child => {:tag => 'td', :content => 53},},
               :descendant => {:tag => 'p',
                               :attributes => {:class => 'day-num'}, :content => '4'},
               :descendant => {:tag => 'p',
                               :attributes => {:class => 'day-num'}, :content => '10'}
  end
end
