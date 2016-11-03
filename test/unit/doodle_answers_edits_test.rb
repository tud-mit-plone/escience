require File.expand_path('../../test_helper', __FILE__)

class DoodleAnswersEditsTest < ActiveSupport::TestCase

  fixtures :users, :projects, :roles, :members, :member_roles,
           :doodles, :doodle_answers, :doodle_answers_edits

  def setup
    @user = User.find(1)
    @answer = DoodleAnswers.find(1)
  end

  def test_create
    answer_edit = DoodleAnswersEdits.new(:author => @user,
                                    :doodle_answers => @answer,
                                    :edited_on => DateTime.new(2015, 10, 4, 12, 00))
    assert answer_edit.save!
  end

  def test_project
    answer_edit = DoodleAnswersEdits.find(1)
    assert_equal answer_edit.doodle_answers.doodle.project, answer_edit.project
  end

  def test_created_on
    answer_edit = DoodleAnswersEdits.find(1)
    assert_equal answer_edit.edited_on, answer_edit.created_on
  end
end
