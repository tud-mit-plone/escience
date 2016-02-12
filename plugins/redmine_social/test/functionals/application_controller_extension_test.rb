require File.expand_path('../../../../../test/test_helper', __FILE__)
require 'chunky_png'

class ApplicationControllerExtensionTest < ActionController::TestCase
  def setup
    # broken naming convention: controller can't infer from TestCase name
    # needed for tests for UserMessagesController
    # but isn't needed for tests for UserMessages
    @controller = ApplicationController.new
  end
  
  test "generated qr code image is quadratic and black and white" do
    begin
      # no route defined for action generate_qr_code
      # we have to define it at manually
      Rails.application.routes.draw { get 'generate_qr_code' => 'application#generate_qr_code' }
      get :generate_qr_code, :p_url => 'http://google.de'
      assert_response :success
      assert_equal 'image/png', @response.header['Content-Type']
      qr_image = ChunkyPNG::Image.from_blob @response.body
      assert qr_image.width == qr_image.height, "qr_image is quadratic"
      assert_black_and_white qr_image
    ensure
      # restore routes
      Rails.application.reload_routes!
    end
  end
  
  private
  
  def assert_black_and_white(image)
    # max difference
    delta = 20
    
    (0..image.width-1).each do |x|
      (0..image.height-1).each do |y|
        rgba = image[x, y]
        alpha = ChunkyPNG::Color.a(rgba)
        red = ChunkyPNG::Color.r(rgba)
        green = ChunkyPNG::Color.g(rgba)
        blue = ChunkyPNG::Color.b(rgba)
        
        is_white = (red - 255).abs <= delta and
          (green - 255).abs <= delta and
          (blue - 255).abs <= delta
          
        is_black = (red - 0).abs <= delta and
          (green - 0).abs <= delta and
          (blue - 0).abs <= delta
        
        assert (is_white or is_black), 
          "Expected white or black pixel at x:#{x}, y:#{y}, but was #{ChunkyPNG::Color.to_hex(rgba)}"
      end
    end
  end
end