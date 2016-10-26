require File.dirname(__FILE__) + '/../test_helper'

class DoodleAnswersControllerTest < ActionController::TestCase
  self.fixture_path= File.join(File.dirname(__FILE__),'../fixtures')
  
  fixtures :doodle_answers_edits

  # Replace this with your real tests.
  def test_truth
    p "yay TEST"
    assert true
  end
end
