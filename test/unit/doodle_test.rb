require File.expand_path('../../test_helper', __FILE__)

class DoodleTest < ActiveSupport::TestCase
  fixtures :users, :projects, :roles, :members, :member_roles,
           :doodles, :doodle_answers, :doodle_answers_edits

  def setup
    @project = Project.find(1)
    @user = @project.members[0].user
    @user2 = User.find(3)
    @doodle = Doodle.find(1)
  end

  def test_creation
    doodle = Doodle.new :title => "Poll",
                        :project => @project,
                        :author => @user,
                        :description => "Please vote",
                        :options => ["A", "B"]
    assert doodle.save!
    assert doodle.watched_by?(@user)
  end

  def test_destroy
    assert @doodle.destroy
    assert_equal 0, DoodleAnswers.count
    assert_equal 0, DoodleAnswersEdits.count
  end

  def test_results
    assert_equal [2, 1], @doodle.results
    assert DoodleAnswers.create! :doodle => @doodle,
                                 :answers => [false, true]
    @doodle.reload
    assert_equal [2, 2], @doodle.results
    assert DoodleAnswers.create! :doodle => @doodle,
                                 :answers => [false, true]
    @doodle.reload
    assert_equal [2, 3], @doodle.results
  end

  def test_active?
    Timecop.freeze @doodle.expiry_date - 1.day do
      assert @doodle.active?
    end
    Timecop.freeze @doodle.expiry_date + 1.day do
      assert !@doodle.active?
    end
    @doodle.locked = true
    assert !@doodle.active?
  end

  def test_winning_columns
    assert_equal [0], @doodle.winning_columns
    assert DoodleAnswers.create! :doodle => @doodle,
                                 :answers => [false, true]
    @doodle.reload
    assert_equal [0, 1], @doodle.winning_columns
    assert DoodleAnswers.create! :doodle => @doodle,
                                 :answers => [false, true]
    @doodle.reload
    assert_equal [1], @doodle.winning_columns
  end

  def test_previewfy
    @doodle.previewfy
    assert @doodle.locked
  end

  def test_user_has_answered
    assert @doodle.user_has_answered?(@user)
    assert !@doodle.user_has_answered?(@user2)
    assert DoodleAnswers.create! :doodle => @doodle,
                                 :answers => [false, true],
                                 :author => @user2
    @doodle.reload
    assert @doodle.user_has_answered?(@user)
    assert @doodle.user_has_answered?(@user2)
  end

  def test_users_missing_answers
    assert_empty @doodle.users_missing_answer
    @doodle.should_answer = [@user, @user2]
    assert_equal [@user2], @doodle.users_missing_answer
    assert DoodleAnswers.create! :doodle => @doodle,
                                 :answers => [false, true],
                                 :author => @user2
    @doodle.reload
    assert_empty @doodle.users_missing_answer
  end
end
