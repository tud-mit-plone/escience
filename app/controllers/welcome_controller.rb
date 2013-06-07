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

class WelcomeController < ApplicationController
  attr_accessor :user
  caches_action :robots

  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper


  def index
    @news = News.latest User.current
    @projects = Project.latest User.current
    
    @user = session[:user].nil? ? User.new : session[:user]
    session[:user] = nil
  end

  def news
      @news = News.latest User.current
      @projects = Project.latest User.current
      @user = session[:user].nil? ? User.new : session[:user]
      session[:user] = nil
  
      case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit =  10
      end
  
        scope = @project ? @project.news.visible : News.visible
      
      @news_count = scope.count
      @news_pages = Paginator.new self, @news_count, @limit, params['page']
      @offset ||= @news_pages.current.offset
      @newss = scope.all(:include => [:author, :project],
                                         :order => "#{News.table_name}.created_on DESC",
                                         :offset => @offset,
                                         :limit => @limit, :conditions => "author_id = 1")

  end

  def events
    @news = News.latest User.current
    @projects = Project.latest User.current
    
    @user = session[:user].nil? ? User.new : session[:user]
    session[:user] = nil
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end
    @year ||= Date.today.year
    @month ||= Date.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    retrieve_query
    @query.group_by = nil
    if @query.valid?
      events = []
      events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :conditions => ["author_id=1 AND ((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                              )
      events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])

      @calendar.events = events
    end

    render :action => 'show', :layout => false if request.xhr?
  end


  def robots
    #@projects = Project.all_public.active
    render :layout => false, :content_type => 'text/plain'
  end
end
