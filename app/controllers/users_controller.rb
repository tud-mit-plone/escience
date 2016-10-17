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

class UsersController < ApplicationController
  before_filter :require_admin, :except => [:show, :user_search, :contact_member_search, :online_live_count, :crop_profile_photo, :upload_profile_photo]
  before_filter :require_login, :only => [:user_search, :contact_member_search,:show,:online_live_count]
  before_filter :find_user, :only => [:show, :edit, :update, :destroy, :edit_membership, :destroy_membership]
  before_filter(:only => [:show]){ |controller| controller.require_user_security(params[:id]) }
  accept_api_auth :index, :show, :create, :update, :destroy

  helper :sort
  include SortHelper
  helper :custom_fields
  include ActionView::Helpers::JavaScriptHelper
  include CustomFieldsHelper

  layout 'base'

  def index
    sort_init 'login', 'asc'
    sort_update %w(login firstname lastname mail admin created_on last_login_on)

    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end
    logger.info("offset: #{@offset},limit #{@limit}, return #{api_offset_and_limit}")
    @status = params[:status] || 1

    scope = User.logged.status(@status)
    scope = scope.like(params[:name]) if params[:name].present?
    scope = scope.in_group(params[:group_id]) if params[:group_id].present?

    @user_count = scope.count
    @user_pages = Paginator.new self, @user_count, @limit, params['page']
    @offset ||= @user_pages.current.offset
    @users =  scope.find :all,
                        :order => sort_clause,
                        :limit  =>  @limit,
                        :offset =>  @offset
    respond_to do |format|
      format.html {
        @groups = Group.all.sort
        render :layout => !request.xhr?
      }
      format.api {}
      format.js{ render :partial => "index_pagination" }
    end
  end

  def user_search
    if params[:q].nil? || params[:q]== '' || params[:q].split('').length < 3
      @users = []
    else
	# User.current.admin
      @users = User.find(:all,
        :select => "firstname, lastname, id",
        :conditions => ['(lastname LIKE ? OR firstname LIKE ?) AND id <> ?',
        "#{params[:q]}%", "#{params[:q]}%", "#{User.current.id}"],:limit => 5, :order => 'lastname')
    end
    respond_to do |format|
      format.xml { render :xml => @users }
#      format.html { render :xml => @users }
      format.js # user_search.js.erb
      format.json { render :json => @users }
    end
  end



  def contact_member_search
    others = []
    if params[:q].nil? || params[:q]== '' || params[:q].split('').length < 3
      @users = []
    else
      @users = User.find(:all,
        :select => "firstname, lastname, id",
        :conditions => ['(lastname LIKE ? OR firstname LIKE ?) AND id <> ? AND security_number & ?',
        "#{params[:q]}%", "#{params[:q]}%", "#{User.current.id}",User.searchable_sql()],:limit => 5, :order => 'lastname')
    end

    respond_to do |format|
      format.js # user_search.js.erb
      format.json { render :json => @users.to_json }
    end
  end

  def show
    # show projects based on current user visibility
    @memberships = @user.memberships.all(:conditions => Project.visible_condition(User.current))

    events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
    @events_by_day = events.group_by(&:event_date)

    unless User.current.admin?
      if !@user.active? #|| (@user != User.current  && @memberships.empty? && events.empty?)
        render_404
        return
      end
    end

    respond_to do |format|
      format.html { render :layout => 'base' }
      format.api
    end
  end

  def new
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
    @auth_sources = AuthSource.find(:all)
  end

  def create
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
    params[:user][:login] = params[:user][:mail]
    @user.safe_attributes = params[:user]
    @user.admin = params[:user][:admin] || false
    @user.login = params[:user][:login]
    @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] unless @user.auth_source_id

    if @user.save
      @user.pref.attributes = params[:pref]
      @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')
      @user.pref.save
      @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

      Mailer.account_information(@user, params[:user][:password]).deliver if params[:send_information]

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_user_successful_create, :id => view_context.link_to(@user.login, user_path(@user)))
          redirect_to(params[:continue] ?
            {:controller => 'users', :action => 'new'} :
            {:controller => 'users', :action => 'edit', :id => @user}
          )
        }
        format.api  {
        render :action => 'show', :status => :created, :location => user_url(@user) }
      end
    else
      @auth_sources = AuthSource.find(:all)
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@user) }
      end
    end
  end

  def edit
    @auth_sources = AuthSource.find(:all)
    @membership ||= Member.new
  end

  def update
    @user.admin = params[:user][:admin] if params[:user][:admin]
    @user.login = params[:user][:login] if params[:user][:login]
    @user.confirm = params[:user][:confirm] if params[:user][:confirm]
    if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
      @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
    end
    #should we do this here?
    #@user.calc_security_number(params[:security])
    #

    @user.safe_attributes = params[:user]
    # Was the account actived ? (do it before User#save clears the change)
    was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
    # TODO: Similar to My#account
    @user.pref.attributes = params[:pref]
    @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')

    if @user.save
      @user.pref.save
      @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

      if was_activated
        Mailer.account_activated(@user).deliver
      elsif @user.active? && params[:send_information] && !params[:user][:password].blank? && @user.auth_source_id.nil?
        Mailer.account_information(@user, params[:user][:password]).deliver
      end

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to_referer_or edit_user_path(@user)
        }
        format.api  { render_api_ok }
      end
    else
      @auth_sources = AuthSource.find(:all)
      @membership ||= Member.new
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|

        format.html {
          flash[:notice] = @user.errors.full_messages
          render :action => :edit }
        format.api  { render_validation_errors(@user) }
      end
    end
  end

  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_back_or_default(users_url) }
      format.api  { render_api_ok }
    end
  end

  def edit_membership
    @auth_sources = AuthSource.find(:all)
    @membership = Member.edit_membership(params[:membership_id], params[:membership], @user)
    @membership.save
    respond_to do |format|
      if @membership.valid?
        format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'memberships' }
        format.js {
          content_for_update = render_to_string :partial => "users/memberships"
          render js: "$('#tab-content-memberships').html('#{escape_javascript(content_for_update)}');"
        }
      else
        format.js {
          render(:update) {|page|
            page.alert(l(:notice_failed_to_save_members, :errors => @membership.errors.full_messages.join(', ')))
          }
        }
      end
    end
  end

  def destroy_membership
    @membership = Member.find(params[:membership_id])
    if @membership.deletable?
      @membership.destroy
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'memberships' }
      format.js {
        content_for_update = render_to_string :partial => "users/memberships"
        render js: "$('#tab-content-memberships').html('#{escape_javascript(content_for_update)}');"
      }
    end
  end

  def online_live_count
    respond_to do |format|
      format.json{ render :json => {:success => true, :data => User.online_live_count.to_json }}
    end
  end


  def upload_profile_photo
    @user = User.find(params[:id])
    @avatar = Photo.new(params[:photo])
    @avatar.name = params[:photo][:filename]
    @avatar.user  = @user
    if @avatar.save
      @user.avatar_id  = @avatar.id
      @user.save!

      @photo = @avatar
    end

    respond_to do |format|
      format.html { render :action => 'show', :layout => false if request.xhr? }
      format.js { render :partial => 'crop_profile_photo' }
    end
  end

  def tag_search
    tags = []
    if params[:q].nil? || params[:q]== '' || params[:q].split('').length < 3
      tags
    else
      tags = ActsAsTaggableOn::Tag.where("name like ?",params[:q])
    end

    respond_to do |format|
      format.xml { render :xml => tags }
      #format.js # user_search.js.erb
      #format.json { render :json => @projects }
    end
  end

  def crop_profile_photo
    @user = User.find(params[:id])
    @avatar = @user.avatar ? @user.avatar : Photo.new(params[:photo])
    @photo = @avatar
    unless params[:avatar_id].nil?
      @user.avatar_id  = params[:avatar_id]
      @user.save!
    end
    return unless request.put?
    @photo.update_attributes(:crop_x => params[:photo][:crop_x],
                                              :crop_y => params[:photo][:crop_y],
                                              :crop_w => params[:photo][:crop_w],
                                              :crop_h => params[:photo][:crop_h])
    respond_to do |format|
      format.html { redirect_to my_account_path }
      format.js { render :partial => 'users/update_profile_photo' }
    end
  end

  def require_user_security(user_id)
    if((User.current.id.to_i == user_id.to_i) ||
      (User.where(:id => user_id).where("security_number & ?",User.account_readable_for_user).to_a.any?) ||
      (User.current.admin?))
      return true
    end
    return render_403
  end

  private

  def find_user
    if params[:id] == 'current'
      require_login || return
      @user = User.current
    else
      @user = User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
