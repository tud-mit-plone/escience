# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)
require 'attachments_controller'

# Re-raise errors caught by the controller.
class AttachmentsController; def rescue_action(e) raise e end; end

class AttachmentsControllerTest < ActionController::TestCase
  fixtures :users, :projects, :roles, :members, :member_roles,
           :enabled_modules, :issues, :trackers, :attachments,
           :versions, :wiki_pages, :wikis, :documents

  def setup
    @controller = AttachmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    set_fixtures_attachments_directory
  end

  def teardown
    set_tmp_attachments_directory
  end

  def test_show_diff
    @request.session[:user_id] = 2
    ['inline', 'sbs'].each do |dt|
      # 060719210727_changeset_utf8.diff
      get :show, :id => 14, :type => dt
      assert_response :success
      assert_template 'diff'
      assert_equal 'text/html', @response.content_type
      assert_tag 'th',
        :attributes => {:class => /filename/},
        :content => /issues_controller.rb\t\(révision 1484\)/
      assert_tag 'td',
        :attributes => {:class => /line-code/},
        :content => /Demande créée avec succès/
    end
    set_tmp_attachments_directory
  end

  def test_show_diff_replcace_cannot_convert_content
    @request.session[:user_id] = 2
    with_settings :repositories_encodings => 'UTF-8' do
      ['inline', 'sbs'].each do |dt|
        # 060719210727_changeset_iso8859-1.diff
        get :show, :id => 5, :type => dt
        assert_response :success
        assert_template 'diff'
        assert_equal 'text/html', @response.content_type
        assert_tag 'th',
          :attributes => {:class => "filename"},
          :content => /issues_controller.rb\t\(r\?vision 1484\)/
        assert_tag 'td',
          :attributes => {:class => /line-code/},
          :content => /Demande cr\?\?e avec succ\?s/
      end
    end
    set_tmp_attachments_directory
  end

  def test_show_diff_latin_1
    @request.session[:user_id] = 2
    with_settings :repositories_encodings => 'UTF-8,ISO-8859-1' do
      ['inline', 'sbs'].each do |dt|
        # 060719210727_changeset_iso8859-1.diff
        get :show, :id => 5, :type => dt
        assert_response :success
        assert_template 'diff'
        assert_equal 'text/html', @response.content_type
        assert_tag 'th',
          :attributes => {:class => "filename"},
          :content => /issues_controller.rb\t\(révision 1484\)/
        assert_tag 'td',
          :attributes => {:class => /line-code/},
          :content => /Demande créée avec succès/
      end
    end
    set_tmp_attachments_directory
  end

  def test_save_diff_type
    user1 = User.find(1)
    user1.pref[:diff_type] = nil
    user1.preference.save
    user = User.find(1)
    assert_nil user.pref[:diff_type]

    @request.session[:user_id] = 1 # admin
    get :show, :id => 5
    assert_response :success
    assert_template 'diff'
    user.reload
    assert_equal "inline", user.pref[:diff_type]
    get :show, :id => 5, :type => 'sbs'
    assert_response :success
    assert_template 'diff'
    user.reload
    assert_equal "sbs", user.pref[:diff_type]
  end

  def test_diff_show_filename_in_mercurial_export
    set_tmp_attachments_directory
    a = Attachment.new(:container => Issue.find(1),
                       :file => uploaded_test_file("hg-export.diff", "text/plain"),
                       :author => User.find(1))
    assert a.save
    assert_equal 'hg-export.diff', a.filename

    @request.session[:user_id] = 2
    get :show, :id => a.id, :type => 'inline'
    assert_response :success
    assert_template 'diff'
    assert_equal 'text/html', @response.content_type
    assert_select 'th.filename', :text => 'test1.txt'
  end

  def test_show_text_file
    @request.session[:user_id] = 2
    get :show, :id => 4
    assert_response :success
    assert_template 'file'
    assert_equal 'text/html', @response.content_type
    set_tmp_attachments_directory
  end

  def test_show_text_file_utf_8
    set_tmp_attachments_directory
    a = Attachment.new(:container => Issue.find(1),
                       :file => uploaded_test_file("japanese-utf-8.txt", "text/plain"),
                       :author => User.find(1))
    assert a.save
    assert_equal 'japanese-utf-8.txt', a.filename

    str_japanese = "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e"
    str_japanese.force_encoding('UTF-8') if str_japanese.respond_to?(:force_encoding)

    @request.session[:user_id] = 2
    get :show, :id => a.id
    assert_response :success
    assert_template 'file'
    assert_equal 'text/html', @response.content_type
    assert_tag :tag => 'th',
               :content => '1',
               :attributes => { :class => 'line-num' },
               :sibling => { :tag => 'td', :content => /#{str_japanese}/ }
  end

  def test_show_text_file_replcace_cannot_convert_content
    set_tmp_attachments_directory
    with_settings :repositories_encodings => 'UTF-8' do
      a = Attachment.new(:container => Issue.find(1),
                         :file => uploaded_test_file("iso8859-1.txt", "text/plain"),
                         :author => User.find(1))
      assert a.save
      assert_equal 'iso8859-1.txt', a.filename

      @request.session[:user_id] = 2
      get :show, :id => a.id
      assert_response :success
      assert_template 'file'
      assert_equal 'text/html', @response.content_type
      assert_tag :tag => 'th',
                 :content => '7',
                 :attributes => { :class => 'line-num' },
                 :sibling => { :tag => 'td', :content => /Demande cr\?\?e avec succ\?s/ }
    end
  end

  def test_show_text_file_latin_1
    set_tmp_attachments_directory
    with_settings :repositories_encodings => 'UTF-8,ISO-8859-1' do
      a = Attachment.new(:container => Issue.find(1),
                         :file => uploaded_test_file("iso8859-1.txt", "text/plain"),
                         :author => User.find(1))
      assert a.save
      assert_equal 'iso8859-1.txt', a.filename

      @request.session[:user_id] = 2
      get :show, :id => a.id
      assert_response :success
      assert_template 'file'
      assert_equal 'text/html', @response.content_type
      assert_tag :tag => 'th',
                 :content => '7',
                 :attributes => { :class => 'line-num' },
                 :sibling => { :tag => 'td', :content => /Demande créée avec succès/ }
      end
  end

  def test_show_text_file_should_send_if_too_big
    Setting.file_max_size_displayed = 512
    Attachment.find(4).update_attribute :filesize, 754.kilobyte

    @request.session[:user_id] = 2
    get :show, :id => 4
    assert_response :success
    assert_equal 'application/x-ruby', @response.content_type
    set_tmp_attachments_directory
  end

  def test_show_other
    @request.session[:user_id] = 2
    get :show, :id => 6
    assert_response :success
    assert_equal 'application/octet-stream', @response.content_type
    set_tmp_attachments_directory
  end

  def test_show_file_from_private_issue_without_permission
    get :show, :id => 15
    assert_redirected_to '/?back_url=http%3A%2F%2Ftest.host%2Fattachments%2F15'
    set_tmp_attachments_directory
  end

  def test_show_file_from_private_issue_with_permission
    @request.session[:user_id] = 2
    get :show, :id => 15
    assert_response :success
    assert_tag 'h2', :content => /private.diff/
    set_tmp_attachments_directory
  end

  def test_show_file_without_container_should_be_denied
    set_tmp_attachments_directory
    attachment = Attachment.create!(:file => uploaded_test_file("testfile.txt", "text/plain"), :author_id => 2)

    @request.session[:user_id] = 2
    get :show, :id => attachment.id
    assert_response 403
  end

  def test_show_invalid_should_respond_with_404
    @request.session[:user_id] = 2
    get :show, :id => 999
    assert_response 404
  end

  def test_download_text_file
    @request.session[:user_id] = 2
    get :download, :id => 4
    assert_response :success
    assert_equal 'application/x-ruby', @response.content_type
    set_tmp_attachments_directory
  end

  def test_download_version_file_with_issue_tracking_disabled
    Project.find(1).disable_module! :issue_tracking
    @request.session[:user_id] = 2
    get :download, :id => 9
    assert_response :success
  end

  def test_download_should_assign_content_type_if_blank
    Attachment.find(4).update_attribute(:content_type, '')
    @request.session[:user_id] = 2
    get :download, :id => 4
    assert_response :success
    assert_equal 'text/x-ruby', @response.content_type
    set_tmp_attachments_directory
  end

  def test_download_missing_file
    get :download, :id => 2
    assert_response 404
    set_tmp_attachments_directory
  end

  def test_download_should_be_denied_without_permission
    get :download, :id => 7
    assert_redirected_to '/?back_url=http%3A%2F%2Ftest.host%2Fattachments%2Fdownload%2F7'
    set_tmp_attachments_directory
  end

  if convert_installed?
    def test_thumbnail
      Attachment.clear_thumbnails
      @request.session[:user_id] = 2

      get :thumbnail, :id => 16
      assert_response :success
      assert_equal 'image/jpeg', response.content_type
    end

    def test_thumbnail_should_not_exceed_maximum_size
      Redmine::Thumbnail.expects(:generate).with {|source, target, size| size == 800}

      @request.session[:user_id] = 2
      get :thumbnail, :id => 16, :size => 2000
    end

    def test_thumbnail_should_round_size
      Redmine::Thumbnail.expects(:generate).with {|source, target, size| size == 250}

      @request.session[:user_id] = 2
      get :thumbnail, :id => 16, :size => 260
    end

    def test_thumbnail_should_return_404_for_non_image_attachment
      @request.session[:user_id] = 2

      get :thumbnail, :id => 15
      assert_response 404
    end

    def test_thumbnail_should_return_404_if_thumbnail_generation_failed
      Attachment.any_instance.stubs(:thumbnail).returns(nil)
      @request.session[:user_id] = 2

      get :thumbnail, :id => 16
      assert_response 404
    end

    def test_thumbnail_should_be_denied_without_permission
      get :thumbnail, :id => 16
      assert_redirected_to '/?back_url=http%3A%2F%2Ftest.host%2Fattachments%2Fthumbnail%2F16'
    end
  else
    puts '(ImageMagick convert not available)'
  end

  def test_destroy_issue_attachment
    set_tmp_attachments_directory
    issue = Issue.find(3)
    @request.session[:user_id] = 2

    assert_difference 'issue.attachments.count', -1 do
      assert_difference 'Journal.count' do
        delete :destroy, :id => 1
        assert_redirected_to '/projects/ecookbook'
      end
    end
    assert_nil Attachment.find_by_id(1)
    j = Journal.first(:order => 'id DESC')
    assert_equal issue, j.journalized
    assert_equal 'attachment', j.details.first.property
    assert_equal '1', j.details.first.prop_key
    assert_equal 'error281.txt', j.details.first.old_value
    assert_equal User.find(2), j.user
  end

  def test_destroy_wiki_page_attachment
    set_tmp_attachments_directory
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      delete :destroy, :id => 3
      assert_response 302
    end
  end

  def test_destroy_project_attachment
    set_tmp_attachments_directory
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      delete :destroy, :id => 8
      assert_response 302
    end
  end

  def test_destroy_version_attachment
    set_tmp_attachments_directory
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      delete :destroy, :id => 9
      assert_response 302
    end
  end

  def test_destroy_without_permission
    set_tmp_attachments_directory
    assert_no_difference 'Attachment.count' do
      delete :destroy, :id => 3
    end
    assert_response 302
    assert Attachment.find_by_id(3)
  end

  test "thumbnail responds image with right size" do
    set_tmp_attachments_directory

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
    set_tmp_attachments_directory

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
    set_tmp_attachments_directory

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
