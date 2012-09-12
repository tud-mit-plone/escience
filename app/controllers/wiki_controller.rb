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

require 'diff'

# The WikiController follows the Rails REST controller pattern but with
# a few differences
#
# * index - shows a list of WikiPages grouped by page or date
# * new - not used
# * create - not used
# * show - will also show the form for creating a new wiki page
# * edit - used to edit an existing or new page
# * update - used to save a wiki page update to the database, including new pages
# * destroy - normal
#
# Other member and collection methods are also used
#
# TODO: still being worked on
class WikiController < ApplicationController
  default_search_scope :wiki_pages
  before_filter :find_wiki, :authorize, :except => :show_all
  before_filter :find_existing_or_new_page, :only => [:show, :edit, :update]
  before_filter :find_existing_page, :only => [:rename, :protect, :history, :diff, :annotate, :add_attachment, :destroy]

  helper :attachments
  include AttachmentsHelper
  helper :watchers
  include Redmine::Export::PDF

  # List of pages, sorted alphabetically and by parent (hierarchy)
  def index
    load_pages_for_index
    @pages_by_parent_id = @pages.group_by(&:parent_id)
  end

  def show_all
    p params
    if params[:q]
      @question = params[:q] || ""
      @question.strip!
      @all_words = params[:all_words] ? params[:all_words].present? : true
      @titles_only = params[:titles_only] ? params[:titles_only].present? : false
  
      projects_to_search =
        case params[:scope]
        when 'all'
          nil
        when 'my_projects'
          User.current.memberships.collect(&:project)
        when 'subprojects'
          @project ? (@project.self_and_descendants.active.all) : nil
        else
          @project
        end

      projects_to_search = Project.find( :all, :conditions => {:is_public =>1})
  
      offset = nil
      begin; offset = params[:offset].to_time if params[:offset]; rescue; end
  
      # quick jump to an issue
      if @question.match(/^#?(\d+)$/) && Issue.visible.find_by_id($1.to_i)
        redirect_to :controller => "issues", :action => "show", :id => $1
        return
      end
  
      @object_types = Redmine::Search.available_search_types.dup
      if projects_to_search.is_a? Project
        # don't search projects
        @object_types.delete('projects')
        # only show what the user is allowed to view
        @object_types = @object_types.select {|o| User.current.allowed_to?("view_#{o}".to_sym, projects_to_search)}
      end
  
      @scope = @object_types.select {|t| params[t]}
      @scope = @object_types if @scope.empty?
  
      # extract tokens from the question
      # eg. hello "bye bye" => ["hello", "bye bye"]
      @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
      # tokens must be at least 2 characters long
      @tokens = @tokens.uniq.select {|w| w.length > 1 }
  
      if !@tokens.empty?
        # no more than 5 tokens to search for
        @tokens.slice! 5..-1 if @tokens.size > 5
  
        @results = []
        @results_by_type = Hash.new {|h,k| h[k] = 0}
  
        limit = 10
        @scope.each do |s|
          r, c = s.singularize.camelcase.constantize.search(@tokens, projects_to_search,
            :all_words => @all_words,
            :titles_only => @titles_only,
            :limit => (limit+1),
            :offset => offset,
            :before => params[:previous].nil?)
          @results += r
          @results_by_type[s] += c
        end
        @results = @results.sort {|a,b| b.event_datetime <=> a.event_datetime}
        if params[:previous].nil?
          @pagination_previous_date = @results[0].event_datetime if offset && @results[0]
          if @results.size > limit
            @pagination_next_date = @results[limit-1].event_datetime
            @results = @results[0, limit]
          end
        else
          @pagination_next_date = @results[-1].event_datetime if offset && @results[-1]
          if @results.size > limit
            @pagination_previous_date = @results[-(limit)].event_datetime
            @results = @results[-(limit), limit]
          end
        end
      else
        @question = ""
      end
      render :layout => false if request.xhr?

    end
    projects = Project.find( :all, :conditions => {:is_public =>1})
    if projects.class != Array
      @projects ||= [projects]
    else
      @projects = projects
    end
    return @projects  
  end


  # List of page, by last update
  def date_index
    load_pages_for_index
    @pages_by_date = @pages.group_by {|p| p.updated_on.to_date}
  end

  # display a page (in editing mode if it doesn't exist)
  def show
    if @page.new_record?
      if User.current.allowed_to?(:edit_wiki_pages, @project) && editable?
        edit
        render :action => 'edit'
      else
        render_404
      end
      return
    end
    if params[:version] && !User.current.allowed_to?(:view_wiki_edits, @project)
      # Redirects user to the current version if he's not allowed to view previous versions
      redirect_to :version => nil
      return
    end
    @content = @page.content_for_version(params[:version])
    if User.current.allowed_to?(:export_wiki_pages, @project)
      if params[:format] == 'pdf'
        send_data(wiki_page_to_pdf(@page, @project), :type => 'application/pdf', :filename => "#{@page.title}.pdf")
        return
      elsif params[:format] == 'html'
        export = render_to_string :action => 'export', :layout => false
        send_data(export, :type => 'text/html', :filename => "#{@page.title}.html")
        return
      elsif params[:format] == 'txt'
        send_data(@content.text, :type => 'text/plain', :filename => "#{@page.title}.txt")
        return
      end
    end
    @editable = editable?
    @sections_editable = @editable && User.current.allowed_to?(:edit_wiki_pages, @page.project) &&
      @content.current_version? &&
      Redmine::WikiFormatting.supports_section_edit?

    render :action => 'show'
  end

  # edit an existing page or a new one
  def edit
    return render_403 unless editable?
    if @page.new_record?
      @page.content = WikiContent.new(:page => @page)
      if params[:parent].present?
        @page.parent = @page.wiki.find_page(params[:parent].to_s)
      end
    end

    @content = @page.content_for_version(params[:version])
    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    # To prevent StaleObjectError exception when reverting to a previous version
    @content.version = @page.content.version
    
    @text = @content.text
    if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
      @section = params[:section].to_i
      @text, @section_hash = Redmine::WikiFormatting.formatter.new(@text).get_section(@section)
      render_404 if @text.blank?
    end
  end

  # Creates a new page or updates an existing one
  def update
    return render_403 unless editable?
    @page.content = WikiContent.new(:page => @page) if @page.new_record?
    @page.safe_attributes = params[:wiki_page]

    @content = @page.content_for_version(params[:version])
    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    if !@page.new_record? && params[:content].present? && @content.text == params[:content][:text]
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      render_attachment_notice_if_upload_failed(attachments)
      
      # don't save content if text wasn't changed
      @page.save
      redirect_to :action => 'show', :project_id => @project, :id => @page.title
      return
    end

    @content.comments = params[:content][:comments]
    @text = params[:content][:text]
    if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
      @section = params[:section].to_i
      @section_hash = params[:section_hash]
      @content.text = Redmine::WikiFormatting.formatter.new(@content.text).update_section(params[:section].to_i, @text, @section_hash)
    else
      @content.version = params[:content][:version]
      @content.text = @text
    end
    @content.author = User.current
    @page.content = @content
    if @page.save
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)

      render_attachment_notice_if_upload_failed(attachments)

      call_hook(:controller_wiki_edit_after_save, { :params => params, :page => @page})
      redirect_to :action => 'show', :project_id => @project, :id => @page.title
    else
      render :action => 'edit'
    end

  rescue ActiveRecord::StaleObjectError, Redmine::WikiFormatting::StaleSectionError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
    render :action => 'edit'
  rescue ActiveRecord::RecordNotSaved
    render :action => 'edit'
  end

  # rename a page
  def rename
    return render_403 unless editable?
    @page.redirect_existing_links = true
    # used to display the *original* title if some AR validation errors occur
    @original_title = @page.pretty_title
    if request.post? && @page.update_attributes(params[:wiki_page])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :project_id => @project, :id => @page.title
    end
  end

  def protect
    @page.update_attribute :protected, params[:protected]
    redirect_to :action => 'show', :project_id => @project, :id => @page.title
  end

  # show page history
  def history
    @version_count = @page.content.versions.count
    @version_pages = Paginator.new self, @version_count, per_page_option, params['p']
    # don't load text
    @versions = @page.content.versions.find :all,
                                            :select => "id, author_id, comments, updated_on, version",
                                            :order => 'version DESC',
                                            :limit  =>  @version_pages.items_per_page + 1,
                                            :offset =>  @version_pages.current.offset

    render :layout => false if request.xhr?
  end

  def diff
    @diff = @page.diff(params[:version], params[:version_from])
    render_404 unless @diff
  end

  def annotate
    @annotate = @page.annotate(params[:version])
    render_404 unless @annotate
  end

  # Removes a wiki page and its history
  # Children can be either set as root pages, removed or reassigned to another parent page
  def destroy
    return render_403 unless editable?

    @descendants_count = @page.descendants.size
    if @descendants_count > 0
      case params[:todo]
      when 'nullify'
        # Nothing to do
      when 'destroy'
        # Removes all its descendants
        @page.descendants.each(&:destroy)
      when 'reassign'
        # Reassign children to another parent page
        reassign_to = @wiki.pages.find_by_id(params[:reassign_to_id].to_i)
        return unless reassign_to
        @page.children.each do |child|
          child.update_attribute(:parent, reassign_to)
        end
      else
        @reassignable_to = @wiki.pages - @page.self_and_descendants
        return
      end
    end
    @page.destroy
    redirect_to :action => 'index', :project_id => @project
  end

  # Export wiki to a single pdf or html file
  def export
    @pages = @wiki.pages.all(:order => 'title', :include => [:content, :attachments], :limit => 75)
    respond_to do |format|
      format.html {
        export = render_to_string :action => 'export_multiple', :layout => false
        send_data(export, :type => 'text/html', :filename => "wiki.html")
      }
      format.pdf {
        send_data(wiki_pages_to_pdf(@pages, @project), :type => 'application/pdf', :filename => "#{@project.identifier}.pdf")
      }
    end
  end

  def preview
    page = @wiki.find_page(params[:id])
    # page is nil when previewing a new page
    return render_403 unless page.nil? || editable?(page)
    if page
      @attachements = page.attachments
      @previewed = page.content
    end
    @text = params[:content][:text]
    render :partial => 'common/preview'
  end

  def add_attachment
    return render_403 unless editable?
    attachments = Attachment.attach_files(@page, params[:attachments])
    render_attachment_warning_if_needed(@page)
    render_attachment_notice_if_upload_failed(attachments)
    redirect_to :action => 'show', :id => @page.title, :project_id => @project
  end

private

  def find_wiki
    @project = Project.find(params[:project_id])
    @wiki = @project.wiki
    render_404 unless @wiki
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Finds the requested page or a new page if it doesn't exist
  def find_existing_or_new_page
    @page = @wiki.find_or_new_page(params[:id])
    if @wiki.page_found_with_redirect?
      redirect_to params.update(:id => @page.title)
    end
  end

  # Finds the requested page and returns a 404 error if it doesn't exist
  def find_existing_page
    @page = @wiki.find_page(params[:id])
    if @page.nil?
      render_404
      return
    end
    if @wiki.page_found_with_redirect?
      redirect_to params.update(:id => @page.title)
    end
  end

  # Returns true if the current user is allowed to edit the page, otherwise false
  def editable?(page = @page)
    page.editable_by?(User.current)
  end

  # Returns the default content of a new wiki page
  def initial_page_content(page)
    helper = Redmine::WikiFormatting.helper_for(Setting.text_formatting)
    extend helper unless self.instance_of?(helper)
    helper.instance_method(:initial_page_content).bind(self).call(page)
  end

  def load_pages_for_index
    @pages = @wiki.pages.with_updated_on.all(:order => 'title', :include => {:wiki => :project})
  end
end
