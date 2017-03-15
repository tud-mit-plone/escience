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

class ActivitiesController < ApplicationController
  menu_item :activity
  before_filter :find_optional_project
  before_filter :require_login, :only => [:show, :index]
  accept_rss_auth :index

  def index
    begin  
      events = activity_index_for_project
      if events.empty? || stale?(:etag => [@activity.scope, @date_to, @date_from, @with_subprojects, @author, events.first, events.size, User.current, current_language])
        respond_to do |format|
          format.html {
            @events_by_day
            render :layout => false if request.xhr?
          }
          format.atom {
            title = l(:label_activity)
            if @author
              title = @author.name
            elsif @activity.scope.size == 1
              title = l("label_#{@activity.scope.first.singularize}_plural")
            end
            render_feed(events.values.flatten, :title => "#{@project || Setting.app_title}: #{title}")
          }
        end
      end

    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
  
  private

  # TODO: refactor, duplicated in projects_controller
  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
