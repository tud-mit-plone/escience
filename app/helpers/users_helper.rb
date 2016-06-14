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

module UsersHelper
  def users_status_options_for_select(selected)
    user_count_by_status = User.count(:group => 'status').to_hash
    options_for_select([[l(:label_all), ''],
                        ["#{l(:status_active)} (#{user_count_by_status[1].to_i})", '1'],
                        ["#{l(:status_registered)} (#{user_count_by_status[2].to_i})", '2'],
                        ["#{l(:status_locked)} (#{user_count_by_status[3].to_i})", '3']], selected.to_s)
  end

  # Options for the new membership projects combo-box
  def options_for_membership_project_select(user, projects)
    options = content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---")
    options << project_tree_options_for_select(projects) do |p|
      {:disabled => (user.projects.include?(p))}
    end
    options
  end

  def user_mail_notification_options(user)
    user.valid_notification_options.collect {|o| [l(o.last), o.first]}
  end

  def change_status_link(user,options={})
    options = {:no_text => false}.merge(options)

    lock_class = options[:lock][:html_class].to_s unless options[:lock].nil?
    activate_class = options[:activate][:html_class].to_s unless options[:activate].nil?
    unlock_class = options[:unlock][:html_class].to_s unless options[:unlock].nil?

    url = {:controller => 'users', :action => 'update', :id => user, :page => params[:page], :status => params[:status], :tab => nil}

    if user.locked?
      link_to options[:no_text] ? '<i class="icon-unlock-alt"></i>'.html_safe : l(:button_unlock), url.merge(:user => {:status => User::STATUS_ACTIVE}), :method => :put, :class => unlock_class
    elsif user.registered?
      link_to options[:no_text] ? '<i class="icon-signin"></i>'.html_safe : l(:button_activate), url.merge(:user => {:status => User::STATUS_ACTIVE}), :method => :put, :class => activate_class
    elsif user != User.current
      link_to options[:no_text] ? '<i class="icon-lock"></i>'.html_safe : l(:button_lock), url.merge(:user => {:status => User::STATUS_LOCKED}), :method => :put, :class => lock_class
    end
  end

  def user_settings_tabs
    tabs = [{:name => 'general', :partial => 'users/general', :label => :label_general},
            {:name => 'memberships', :partial => 'users/memberships', :label => :label_project_plural}
            ]
    if Group.all.any?
      tabs.insert 1, {:name => 'groups', :partial => 'users/groups', :label => :label_group_plural}
    end
    tabs
  end
  
  def member_tabs
    tabs = [{:name => 'contact_members', :partial => 'users/contact_members', :label => :label_memberlist_all},
#            {:name => 'contact_membersgrouped', :partial => 'users/contact_membersgrouped', :label => :label_memberlist_grouped},
            {:name => 'contact_membersearch', :partial => 'users/contact_membersearch', :label => :label_memberlist_search}
            ]
    tabs
  end
    
end
