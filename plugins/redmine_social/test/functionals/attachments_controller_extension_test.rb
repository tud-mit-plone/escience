require File.expand_path('../../../../../test/test_helper', __FILE__)

class AttachmentsControllerExtensionTest < ActionController::TestCase
  self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"
  
  fixtures :users, :issues, :projects
  
  def setup
    # broken naming convention: controller can't infer from TestCase name
    # so we have to set it manually
    @controller = AttachmentsController.new
    
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
    
    # fixture_file_upload (called by uploaded_test_file) has a bug.
    # It calls fixture_path method on TestCase not on the overriden
    # method. We have to repair the fixture_path manually.
    fix_fixture_path
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end

  test "thumbnail responds image with right size" do
    container = issues(:issues_001)
    author = users(:users_002)
    file = uploaded_test_file("simons_cat.jpg", "image/jpeg")
    attachment = create_attachment(container, author, file)

    @request.session[:user_id] = author.id
    get :thumbnail, :id => attachment.id, :size => 100, :pages => 1
    assert_response :success
    thumbnail = Magick::Image.from_blob(@response.body).first
    assert_not_nil thumbnail
    width, height = thumbnail.columns, thumbnail.rows
    # either width or height is 100px. the other side should less or equal
    assert_equal 100, [width, height].max
  end
  
  test "thumbnail responds thumbnail only if not cached" do
    container = issues(:issues_001)
    author = users(:users_002)
    file = uploaded_test_file("simons_cat.jpg", "image/jpeg")
    attachment = create_attachment(container, author, file)
    
    # first get request. thumbnail has to be responds
    @request.session[:user_id] = author.id
    get :thumbnail, :id => attachment.id, :size => 100, :pages => 1
    assert_response :success
    etag = @response.headers["ETag"]
    
    # simulate caching
    # the client has allready downloaded the thumbnail with the same etag
    @request.if_none_match = etag
    get :thumbnail, :id => attachment.id, :size => 100, :pages => 1
    # the client has a fresh copy of the thumbnail
    # so he gets a 304 (not modified) and no thumbnail is sent
    assert_response 304
  end
  
  test "show responds the right form for the content type" do
    container = issues(:issues_001)
    author = users(:users_002)
    @request.session[:user_id] = author.id
        
    # show can differentiate between diff, text, pdf, xls and other
    # upload all attachments
    file = uploaded_test_file("subversion.diff", "text/plain")
    diff_attachment = create_attachment(container, author, file)
    
    file = uploaded_test_file("lorem_hipsum.txt", "text/plain")
    text_attachment = create_attachment(container, author, file)
    
    file = uploaded_test_file("lorem_hipsum_2_pager.pdf", "application/pdf")
    pdf_attachment = create_attachment(container, author, file)
    
    file = uploaded_test_file("lorem_hipsum.xls", "application/vnd.ms-excel")
    xls_attachment = create_attachment(container, author, file)
    
    file = uploaded_test_file("simons_cat.jpg", "image/jpeg")
    other_attachment = create_attachment(container, author, file)
    
    # diffs/patches rendered in a special template to colorize differences
    # also show memorize the display type (inline or sbs) as user preferences
    get :show, :id => diff_attachment.id, :type => 'inline'
    assert_response :success
    assert_template :diff
    assert_not_nil assigns(:diff)
    assert_equal 'inline', assigns(:diff_type)
    assert 'inline', author.pref[:diff_type]
    
    # texts rendered in a special template that can do syntax highlighting
    get :show, :id => text_attachment.id
    assert_response :success
    assert_template :file
    assert_not_nil assigns(:content)
    
    # pdfs previewed by a 1000px thumbnial
    get :show, :id => pdf_attachment.id, :pages => 1
    assert_response :success
    assert_template :render_show
    
    # excel spreadsheets sent back as images
    get :show, :id => xls_attachment.id, :pages => 1
    assert_response :success
    thumbnail = Magick::Image.from_blob(@response.body).first
    assert_not_nil thumbnail
    
    # other files sent as download
    get :show, :id => other_attachment.id
    assert_response :success
    assert_equal other_attachment.filesize, @response.body.length
    assert_equal 'binary', @response.header['Content-Transfer-Encoding']
  end
  
  private
  
  # Because a bug, a overriden fixture_path method get not called for files,
  # so we have to set the variable manually.
  # https://github.com/rspec/rspec-rails/issues/252#issuecomment-1438267
  def fix_fixture_path
    ActiveSupport::TestCase.class_eval do
      include ActiveRecord::TestFixtures
      self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"
    end
  end
  
  def create_attachment(container, author, file)
    User.current = author
    
    # An Attachment needs at least one MetaInformation
    meta = MetaInformation.new(
      :meta_information => 'Foo',
      :user => author
    )
    meta.save!
    
    attachment = Attachment.new(
      :container => container,
      :file => file,
      :author => author,
      :meta_information => [meta]
    )
    attachment.save!
    
    attachment
  end
end