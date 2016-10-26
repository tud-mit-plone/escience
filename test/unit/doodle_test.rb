require File.dirname(__FILE__) + '/../test_helper'

class DoodlesControllerTest < ActionController::TestCase
  self.fixture_path= File.join(File.dirname(__FILE__),'../fixtures')
  fixtures :doodles

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
