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

class CalendarsController < ApplicationController
  menu_item :calendar
  before_filter :find_optional_project
  before_filter :require_login, :only => [:show, :index]

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper

  def show
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end
    @year ||= Date.today.year
    @month ||= Date.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    unless (@project.nil? || params['sub'].nil? || session[:current_view_of_eScience] == "0")
      bufferProjectId = @project
      session[:query][:project_id] = nil unless session[:query].nil?
      @project = nil
    end
    retrieve_query
    unless (bufferProjectId.nil?)
      @project = bufferProjectId
      session[:query][:project_id] = @project.id
    end
    @query.group_by = nil
    if @query.valid?
      creator = User.current.id.to_s if session[:current_view_of_eScience]== "0"
      events ||=[]
      
      if creator.nil? 
        events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt])
      else
        events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?)) AND creator=?", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt,creator])  
      end 
      events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])

      @calendar.events = events
    end

    respond_to do |format|
      format.html { render :action => 'show', :layout => false if request.xhr? }
      format.js { render :partial => 'update' }
    end
  end
end
