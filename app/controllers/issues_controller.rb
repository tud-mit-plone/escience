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

class IssuesController < ApplicationController
  menu_item :new_issue, :only => [:new, :create, :new_with_descision]
  default_search_scope :issues

  before_filter :find_issue, :only => [:show, :edit, :update]
  before_filter :find_issues, :only => [:bulk_edit, :bulk_update, :destroy]
  before_filter :find_project, :only => [:new, :create]
  before_filter :authorize, :except => [:index, :new_with_decision]
  before_filter :find_optional_project, :only => [:index, :new_with_descision]
  before_filter :check_for_default_issue_status, :only => [:new, :create]
  before_filter :correct_time_format, :only => [:new, :create]
  before_filter :build_new_issue_from_params, :only => [:new, :create]
  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  helper :gantt
#  include ApplicationHelper
  include Redmine::Export::PDF

  def index
    # byebug
    unless params['id'].nil?
      @project = Project.find(params['id']);
    else
      unless (params['sub'].nil? || !params['set_filter'].nil?)
        bufferProjectId = @project
        unless session[:query].nil?
          session[:query][:project_id] = nil
        end
        @project = nil
        params["f"] = !params['f'].nil? && !params['f'].include?('project_id') ? params['f'] : ["status_id", "assigned_to_id"]
        params["op"] = !params['op'].nil? && !params['op'][:project_id].nil? ? params['op'] : {"status_id"=>"o", "assigned_to_id"=>"="}
        params["v"] = !params['v'].nil? && !params['v'][:project_id].nil? ? params['v'] : {:assigned_to_id => ["me"] }
      end
    end
    params["c"] = ["project", "tracker", "status", "priority", "subject", "assigned_to", "updated_on"]
    params["group_by"] = "project"
    params["per_page"] = "150"
    params["set_filter"] = "1"

    retrieve_query
    unless (bufferProjectId.nil?)
      @project = bufferProjectId
    end
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      case params[:format]
      when 'csv', 'pdf'
        @limit = Setting.issues_export_limit.to_i
      when 'atom'
        @limit = Setting.feeds_limit.to_i
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
      end

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new self, @issue_count, @limit, params['page']
      @offset ||= @issue_pages.current.offset
      if !params[:sub].nil? && session[:current_view_of_eScience] == "0"
        @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                                :conditions => ["(creator = #{User.current.id} AND issues.parent_id IS NULL)"],
                                :order => sort_clause,
                                :offset => @offset,
                                :limit => @limit)
      else
        @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                                :conditions => ["(issues.parent_id IS NULL)"],
                                :order => sort_clause,
                                :offset => @offset,
                                :limit => @limit)
      end
      @issue_count_by_group = @query.issue_count_by_group

      if !(params[:group_by].nil? || params[:group_by].empty?)
        @query.group_by = params[:group_by].to_sym
      else
        params[:group_by] = 'project'
        @query.group_by = params[:group_by].to_sym
      end
      if !@query.group_by.nil?
        @issues_by_group = @issues.group_by {|i| column_plain_content(@query.group_by, i) }.sort()
      else
        @issues_by_group = { "" => @issues }
      end


      respond_to do |format|
        format.html { render :template => 'issues/index', :layout => !request.xhr? }
        format.api  {
          Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
        }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(issues_to_csv(@issues, @project, @query, params), :type => 'text/csv; header=present', :filename => 'export.csv') }
        format.pdf  { send_data(issues_to_pdf(@issues, @project, @query), :type => 'application/pdf', :filename => 'export.pdf') }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show
    if session[:current_view_of_eScience] == "0"
      @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    else
      @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    end
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    @journals.reverse! if User.current.wants_comments_in_reverse_order?

    @changesets = @issue.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?

    @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    @subissue = @issue.parent_id.nil? ? nil : Issue.find(@issue.parent_id)
    respond_to do |format|
      format.html {
        retrieve_previous_and_next_issue_ids
        render :template => 'issues/show'
      }
      format.api
      format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf  {
        pdf = issue_to_pdf(@issue, :journals => @journals)
        send_data(pdf, :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf")
      }
    end
  end

  # Add a new issue
  # The new issue will be created from an existing one if copy_from parameter is given
  def new
    respond_to do |format|
      format.html { render :action => 'new', :layout => !request.xhr? }
      format.js { render :partial => 'update_form' }
    end
  end

  def new_with_decision
    if session[:current_view_of_eScience] == "0"
        @projects = Project.private_scope.all
    else
    end
    unless params[:issue].nil?
      @selected_project = Project.find(params[:issue][:project_id])
      @project = @selected_project
    else
      @project = @projects.first
    end
    build_new_issue_from_params()
    @project = nil

    respond_to do |format|
      format.html { render :action => 'new_with_decision', :layout => !request.xhr? }
      format.js {
        render :partial => 'update_form_with_decision'
      }
    end
  end

  def create
    call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
    @issue.description = convertHtmlToWiki(params[:issue][:description])

    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    @issue.parent_issue_id = params[:parent_id]
    if @issue.save
      call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@issue)
          flash[:notice] = l(:notice_issue_successful_create, :id => "<a href='#{issue_path(@issue)}'>##{@issue.id}</a>")
          if params[:continue]
            if params[:form] == 'new_with_decision'
              @projects = Project.private_scope.all
              redirect_to({ :action => 'new_with_decision'})
            else
              redirect_to({ :action => 'new', :project_id => @issue.project, :issue => {:tracker_id => @issue.tracker, :parent_issue_id => @issue.parent_issue_id}.reject {|k,v| v.nil?} })
            end
          else
            redirect_to({ :action => 'show', :id => @issue })
          end
        }
        format.api  { render :action => 'show', :status => :created, :location => issue_url(@issue) }
      end
      return
    else
      flash[:notice] = l(:notice_issue_error_create)+"<br>"+@issue.errors.full_messages * '<br>'
      respond_to do |format|
        format.html {
          if params[:form] == 'new_with_decision'
            @projects = Project.private_scope.all
            flash[:notice] = l(:notice_issue_error_create)+"<br>"+@issue.errors.full_messages * '<br>'
            render :action => 'new_with_decision'
          else
            render :action => 'new'
          end
        }
        format.api  { render_validation_errors(@issue) }
      end
    end
  end

  def edit
    return unless update_issue_from_params

    respond_to do |format|
      format.html { }
      format.xml  { }
    end
  end

  def update
    unless params[:issue][:start_date].nil?
      params[:issue][:description] = convertHtmlToWiki(params[:issue][:description])
      params[:issue][:start_date] = params[:issue][:start_date].empty? ? '':format_date(params[:issue][:start_date])
      params[:issue][:due_date] = params[:issue][:due_date].empty? ? '':format_date(params[:issue][:due_date])
      @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
      saved = false
    end
    return unless update_issue_from_params

    begin
      saved = @issue.save_issue_with_child_records(params, @time_entry)
    rescue ActiveRecord::StaleObjectError
      @conflict = true
      if params[:last_journal_id]
        @conflict_journals = @issue.journals_after(params[:last_journal_id]).all
        @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
      end
    end

    if saved
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?

      respond_to do |format|
        format.html { redirect_back_or_default({:action => 'show', :id => @issue}) }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@issue) }
      end
    end
  end

  # Bulk edit/copy a set of issues
  def bulk_edit
    @issues.sort!
    @copy = params[:copy].present?
    @notes = params[:notes]

    if User.current.allowed_to?(:move_issues, @projects)
      @allowed_projects = Issue.allowed_target_projects_on_move
      if params[:issue]
        @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:issue][:project_id].to_s}
        if @target_project
          target_projects = [@target_project]
        end
      end
    end
    target_projects ||= @projects

    if @copy
      @available_statuses = [IssueStatus.default]
    else
      @available_statuses = @issues.map(&:new_statuses_allowed_to).reduce(:&)
    end
    @custom_fields = target_projects.map{|p|p.all_issue_custom_fields}.reduce(:&)
    @assignables = target_projects.map(&:assignable_users).reduce(:&)
    @trackers = target_projects.map(&:trackers).reduce(:&)
    @versions = target_projects.map {|p| p.shared_versions.open}.reduce(:&)
    @categories = target_projects.map {|p| p.issue_categories}.reduce(:&)
    if @copy
      @attachments_present = @issues.detect {|i| i.attachments.any?}.present?
      @subtasks_present = @issues.detect {|i| !i.leaf?}.present?
    end

    @safe_attributes = @issues.map(&:safe_attribute_names).reduce(:&)
    render :layout => false if request.xhr?
  end

  def bulk_update
    @issues.sort!
    @copy = params[:copy].present?
    attributes = parse_params_for_bulk_issue_attributes(params)

    unsaved_issue_ids = []
    moved_issues = []

    if @copy && params[:copy_subtasks].present?
      # Descendant issues will be copied with the parent task
      # Don't copy them twice
      @issues.reject! {|issue| @issues.detect {|other| issue.is_descendant_of?(other)}}
    end

    @issues.each do |issue|
      issue.reload
      if @copy
        issue = issue.copy({},
          :attachments => params[:copy_attachments].present?,
          :subtasks => params[:copy_subtasks].present?
        )
      end
      journal = issue.init_journal(User.current, params[:notes])
      issue.safe_attributes = attributes
      call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })
      if issue.save
        moved_issues << issue
      else
        # Keep unsaved issue ids to display them in flash error
        unsaved_issue_ids << issue.id
      end
    end
    set_flash_from_bulk_issue_save(@issues, unsaved_issue_ids)

    if params[:follow]
      if @issues.size == 1 && moved_issues.size == 1
        redirect_to :controller => 'issues', :action => 'show', :id => moved_issues.first
      elsif moved_issues.map(&:project).uniq.size == 1
        redirect_to :controller => 'issues', :action => 'index', :project_id => moved_issues.map(&:project).first
      end
    else
      redirect_back_or_default({:controller => 'issues', :action => 'index', :project_id => @project})
    end
  end

  def destroy
    @hours = TimeEntry.sum(:hours, :conditions => ['issue_id IN (?)', @issues]).to_f
    if @hours > 0
      case params[:todo]
      when 'destroy'
        # nothing to do
      when 'nullify'
        TimeEntry.update_all('issue_id = NULL', ['issue_id IN (?)', @issues])
      when 'reassign'
        reassign_to = @project.issues.find_by_id(params[:reassign_to_id])
        if reassign_to.nil?
          flash.now[:error] = l(:error_issue_not_found_in_project)
          return
        else
          TimeEntry.update_all("issue_id = #{reassign_to.id}", ['issue_id IN (?)', @issues])
        end
      else
        # display the destroy form if it's a user request
        return unless api_request?
      end
    end
    @issues.each do |issue|
      begin
        issue.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
        # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(:action => 'index', :project_id => @project) }
      format.api  { render_api_ok }
    end
  end

private

  def formated_date_to_db(date)
    return nil if date.nil? || date.empty? || date.blank?
    d = nil
    unless Setting.date_format.blank?
      d = Date.strptime(date, Setting.date_format )
    else
     d = Date.strptime(date,::I18n.t("date.formats.default",{ :locale => User.current.language }))
    end
    return d
  end

  def correct_time_format()
    return if params.nil? || params[:issue].nil?

    unless params[:issue][:start_date].nil?
      params[:issue][:start_date] = formated_date_to_db(params[:issue][:start_date])
    end
    unless params[:issue][:due_date].nil?
      params[:issue][:due_date] = formated_date_to_db(params[:issue][:due_date])
    end
  end

  # Retrieve query from session or build a new query
  def column_plain_content(column_name, issue)
    column = @query.columns.find{|c| c.name == column_name}
		if column.nil?
			issue.project.parent ? issue.project.parent.name : issue.project.name if column_name == :main_project
		else
			if column.is_a?(QueryCustomFieldColumn)
				cv = issue.custom_values.detect {|v| v.custom_field_id == column.custom_field.id}
				show_value(cv)
			else
				value = issue.send(column.name.to_s)
				if value.is_a?(Date)
					format_date(value)
				elsif value.is_a?(Time)
					format_time(value)
				elsif column.name == :done_ratio
          value.to_s.rjust(3) << '%'
				else
					value.to_s
				end
			end
		end
  end

  def find_issue
    # Issue.visible.find(...) can not be used to redirect user to the login form
    # if the issue actually exists but requires authentication
    @issue = Issue.find(params[:id], :include => [:project, :tracker, :status, :author, :priority, :category])
    unless @issue.visible?
      deny_access
      return
    end
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    project_id = params[:project_id] || (params[:issue] && params[:issue][:project_id])
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def retrieve_previous_and_next_issue_ids
    retrieve_query_from_session
    if @query
      sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
      sort_update(@query.sortable_columns, 'issues_index_sort')
      limit = 500
      issue_ids = @query.issue_ids(:order => sort_clause, :limit => (limit + 1), :include => [:assigned_to, :tracker, :priority, :category, :fixed_version])
      if (idx = issue_ids.index(@issue.id)) && idx < limit
        if issue_ids.size < 500
          @issue_position = idx + 1
          @issue_count = issue_ids.size
        end
        @prev_issue_id = issue_ids[idx - 1] if idx > 0
        @next_issue_id = issue_ids[idx + 1] if idx < (issue_ids.size - 1)
      end
    end
  end

  # Used by #edit and #update to set some common instance variables
  # from the params
  # TODO: Refactor, not everything in here is needed by #edit
  def update_issue_from_params
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    @time_entry.attributes = params[:time_entry]

    @issue.init_journal(User.current)

    issue_attributes = params[:issue]
    if issue_attributes && params[:conflict_resolution]
      case params[:conflict_resolution]
      when 'overwrite'
        issue_attributes = issue_attributes.dup
        issue_attributes.delete(:lock_version)
      when 'add_notes'
        issue_attributes = issue_attributes.slice(:notes)
      when 'cancel'
        redirect_to issue_path(@issue)
        return false
      end
    end
    @issue.safe_attributes = issue_attributes
    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    true
  end

  # TODO: Refactor, lots of extra code in here
  # TODO: Changing tracker on an existing issue should not trigger this
  def build_new_issue_from_params
    if params[:id].blank?
      @issue = Issue.new
      if params[:copy_from]
        begin
          @copy_from = Issue.visible.find(params[:copy_from])
          @copy_attachments = params[:copy_attachments].present? || request.get?
          @copy_subtasks = params[:copy_subtasks].present? || request.get?
          @issue.copy_from(@copy_from, :attachments => @copy_attachments, :subtasks => @copy_subtasks)
        rescue ActiveRecord::RecordNotFound
          render_404
          return
        end
      end
      @issue.project = @project
    else
      @issue = @project.issues.visible.find(params[:id])
    end

    @issue.project = @project
    @issue.author ||= User.current
    # Tracker must be set before custom field values
    @issue.tracker ||= @project.trackers.find((params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first)
    if @issue.tracker.nil?
      render_error l(:error_no_tracker_in_project)
      return false
    end
    @issue.start_date ||= Date.today if Setting.default_issue_start_date_to_creation_date?
    @issue.safe_attributes = params[:issue]

    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
    @available_watchers = (@issue.project.users.sort + @issue.watcher_users).uniq
  end

  def check_for_default_issue_status
    if IssueStatus.default.nil?
      render_error l(:error_no_default_issue_status)
      return false
    end
  end

  def parse_params_for_bulk_issue_attributes(params)
    attributes = (params[:issue] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    if custom = attributes[:custom_field_values]
      custom.reject! {|k,v| v.blank?}
      custom.keys.each do |k|
        if custom[k].is_a?(Array)
          custom[k] << '' if custom[k].delete('__none__')
        else
          custom[k] = '' if custom[k] == '__none__'
        end
      end
    end
    attributes
  end
end
