require File.expand_path('../../test_helper', __FILE__)

class DoodleAnswersTest < ActiveSupport::TestCase
  fixtures :users, :projects, :roles, :members, :member_roles,
           :doodles, :doodle_answers, :doodle_answers_edits

  def setup
    @user = User.find(1)
    @doodle = Doodle.find(1)
  end

  def test_create
    answers = DoodleAnswers.new :doodle => @doodle,
                               :author => @user,
                               :answers => [true, false]

    assert answers.save!
    assert_equal 3, @doodle.responses.length
    assert_equal 1, answers.edits.length
    edit = answers.edits[0]
    assert_equal @user, edit.author
    # the dates are not exactly the same, but should be similar
    assert_in_epsilon answers.updated_on.to_i, edit.edited_on.to_i, 2
  end

  def test_answers_with_css_classes
    result = DoodleAnswers.find(1).answers_with_css_classes
    assert_equal 2, result.length
    assert_equal [true, "answer yes"], result[0]
    assert_equal [false, "answer no"], result[1]
  end

  def test_css_classes
    answers = DoodleAnswers.find(1)
    css_classes = answers.css_classes
    assert_equal 2, css_classes.length
    assert_equal "answer yes", css_classes[0]
    assert_equal "answer no", css_classes[1]
  end

  def test_destroy
    # deletion should take its edit with it
    assert_equal 2, DoodleAnswersEdits.count
    assert DoodleAnswers.find(1).destroy
    assert_equal 1, DoodleAnswersEdits.count
  end

end
