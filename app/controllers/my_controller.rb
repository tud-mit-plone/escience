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

class MyController < ApplicationController
  before_filter :require_login

  helper :issues
  helper :users
  helper :custom_fields

  BLOCKS = { 'issuesassignedtome' => :label_assigned_to_me_issues,
             'issuesreportedbyme' => :label_reported_issues,
             'issueswatched' => :label_watched_issues,
             'news' => :label_news_latest,
             'calendar' => :label_calendar,
             'documents' => :label_document_plural,
             'timelog' => :label_spent_time,
           }.merge(Redmine::Views::MyPage::Block.additional_blocks).freeze

  DEFAULT_LAYOUT = {  'left' => ['issuesassignedtome'],
                      'right' => ['issuesreportedbyme']
                   }.freeze

  def index
    page
    render :action => 'page'
  end

  # Show user's page
  def page
    @user = User.current
    @blocks = @user.pref[:my_page_layout] || DEFAULT_LAYOUT
  end

  # Edit user's account
  def account
    @user = User.current
    @pref = @user.pref
    if request.post?
      @user.safe_attributes = params[:user]
      @user.pref.attributes = params[:pref]
      @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')

      @user.security_number = User.calc_security_number(params[:security])

      new_tags = prepare_tag_params(params[:my_interest])
      @user.interest_list = new_tags.uniq
      new_tags = prepare_tag_params(params[:my_skill])
      @user.skill_list = new_tags.uniq

      if @user.save && @user.pref.save
        @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])
        set_language_if_valid @user.language
        flash[:notice] = l(:notice_account_updated)
        redirect_to :action => 'account', :sub => 'my_account'
        return
      end
    end
  end

  # Destroys user's account
  def destroy
    @user = User.current
    unless @user.own_account_deletable?
      redirect_to :action => 'account'
      return
    end

    if request.post? && params[:confirm]
      @user.destroy
      if @user.destroyed?
        logout_user
        flash[:notice] = l(:notice_account_deleted)
      end
      redirect_to home_path
    end
  end

  # Manage user's password
  def password
    @user = User.current
    unless @user.change_password_allowed?
      flash[:error] = l(:notice_can_t_change_password)
      redirect_to :action => 'account'
      return
    end
    if request.post?
      if @user.check_password?(params[:password])
        @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
        if @user.save
          flash[:notice] = l(:notice_account_password_updated)
          redirect_to :action => 'account'
        end
      else
        flash[:error] = l(:notice_account_wrong_password)
      end
    end
  end

  # Create a new feeds key
  def reset_rss_key
    if request.post?
      if User.current.rss_token
        User.current.rss_token.destroy
        User.current.reload
      end
      User.current.rss_key
      flash[:notice] = l(:notice_feeds_access_key_reseted)
    end
    redirect_to :action => 'account'
  end

  # Create a new API key
  def reset_api_key
    if request.post?
      if User.current.api_token
        User.current.api_token.destroy
        User.current.reload
      end
      User.current.api_key
      flash[:notice] = l(:notice_api_access_key_reseted)
    end
    redirect_to :action => 'account'
  end

  # User's page layout configuration
  def page_layout
    @user = User.current
    @blocks = @user.pref[:my_page_layout] || DEFAULT_LAYOUT.dup
    @block_options = []
    BLOCKS.each do |k, v|
      unless %w(top left right).detect {|f| (@blocks[f] ||= []).include?(k) && !(v.class == Hash && v[:multiple] == true)}

        @block_options << [l("my.blocks.#{v}", :default => [v, v.to_s.humanize]), k.dasherize]
      end
    end
  end

  # Add a block to user's page
  # The block is added on top of the page
  # params[:block] : id of the block to add
  def add_block
    block = params[:block].to_s.underscore
    (render :nothing => true; return) unless block && (BLOCKS.keys.include? block)
    @user = User.current
    layout = @user.pref[:my_page_layout] || {}
    # remove if already present in a group
    %w(top left right).each {|f| (layout[f] ||= []).delete(block) unless BLOCKS[f].class == Hash && v[:multiple] == true}
    # add it on top
    layout['top'].unshift create_block_name_with_number(layout, block)

    @user.pref[:my_page_layout] = layout
    @user.pref.save
    redirect_to :action => 'page_layout'
  end

  def create_block_name_with_number(layout, block)
    return block unless BLOCKS[block].class == Hash && BLOCKS[block][:multiple] == true
    block_nr = 0
    block = block.split('_').first

    layout.each do |k,v|
      v.each do |active_block|
        if active_block.split('_').first == block
          block_nr = active_block.split('_').last.to_i + 1 if active_block.split('_').last.to_i >= block_nr
        end
      end
    end
    return "#{block}_#{block_nr}"
  end

  def render_block
    if params['blockname'].nil?
      redirect_to :action => 'index', :user_id => User.current.id
    else
      action = params['blockaction'].nil? ? 'index' : params['blockaction']
      url = {:controller => params['blockname'], :action => params['blockaction'], :user_id => User.current.id}
      redirect_to url.merge!(params.except(:controller, :action,:blockaction, :blockname))
    end
  end

  def sanitize_url(url)
    if url.split("://").count > 1
      unless url.split("://").first.include?("http") || url.split("://").first.include?("https")
        url = "http://#{url.split("://")[1]}"
      end
    else
      url = "http://#{url}"
    end
    return url
  end

  # Remove a block to user's page
  # params[:block] : id of the block to remove
  def remove_block
    block = params[:block].to_s.underscore

    block += "_#{params[:block_no]}" unless params[:block_no].nil? || params[:block_no] == ''
    @user = User.current
    # remove block in all groups

    layout = @user.pref[:my_page_layout] || {}
    %w(top left right).each {|f| (layout[f] ||= []).delete block}
    @user.pref[:my_page_layout] = layout
    @user.pref.save
    redirect_to :action => 'page_layout'
  end

  # Change blocks order on user's page
  # params[:group] : group to order (top, left or right)
  # params[:list-(top|left|right)] : array of block ids of the group
  def order_blocks
    group = params[:group]
    @user = User.current
    if group.is_a?(String)
      group_items = (params["blocks"] || []).collect(&:underscore)
      group_items.each {|s| s.sub!(/^block_/, '')}
      if group_items and group_items.is_a? Array
        layout = @user.pref[:my_page_layout] || {}
        # remove group blocks if they are presents in other groups
        %w(top left right).each {|f|
          layout[f] = (layout[f] || []) - group_items
        }
        layout[group] = group_items
        @user.pref[:my_page_layout] = layout
        @user.pref.save
      end
    end
    render :nothing => true
  end

  def members
    @allusers = []
    unless User.current.anonymous?
      User.current.user_contacts.each do |uc|
      @allusers << uc.contact_member
      end unless User.current.user_contacts.nil?
    end

    respond_to do |format|
      format.html
    end
  end

  def contact_members
    @allusers = []
    unless User.current.anonymous?
      User.current.user_contacts.each do |uc|
      @allusers << uc.contact_member
      end unless User.current.user_contacts.nil?
    end

    respond_to do |format|
      format.html
    end
  end

  def interest_search
    q = "%#{params[:q]}%"
    interest_tag = User.interest_counts.arel_table
    interests = User.interest_counts.where(interest_tag[:name].matches(q))

    respond_to do |format|
      format.xml { render :xml => interests }
      format.json { render :json => interests }
    end
  end

  def skill_search
    q = "%#{params[:q]}%"
    skill_tag = User.skill_counts.arel_table
    skills = User.skill_counts.where(skill_tag[:name].matches(q))

    respond_to do |format|
      format.xml { render :xml => skills }
      format.json { render :json => skills }
    end
  end

  def prepare_tag_params(tag_list)
    tag_list = tag_list.split(',')
    ids = []
    tags = []

    tag_list.each do |tag|
      if(tag =~ /^[0-9]+$/)
        tags << ActsAsTaggableOn::Tag.where(:id => tag).map(&:name)
      else
        tags << tag.gsub(" ","")
      end
    end
    return tags
  end
end
