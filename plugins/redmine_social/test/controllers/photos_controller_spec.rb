# test/controllers/photos_controller_spec.rb
#require "./plugins/redmine_social/init.rb"
require "./app/controllers/photos_controller"
# Testfall noch Falsch
RSpec.describe PhotosController do
	describe '#show' do
		context 'when logged in' do
			# test-User einloggen. noch falsch
			before {@user = User.find(2)}
			# before {@photo = }
			it 'show photo' do
				expect(PhotosController.show).to respond_with_content_type(:html)
			end
		end
		context 'when not logged in' do
			it 'show photo without user' do
				expect(PhotosController.show).not_to respond_with_content_type(:html)
			end
		end
	end

	describe '#new' do
		# test-User einloggen. noch falsch
		before {@user = User.find(2)}
		it 'render layout' do
			expect(PhotosController.new).to render_template(layout: true)
		end

	end

	describe '#recent' do
		it 'return not nil' do
			expect(PhotosController.recent).not_to be_nil
		end
	end


end