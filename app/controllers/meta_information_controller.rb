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

class MetaInformationController < ApplicationController

  before_filter :require_login, :only => [:retrieve_all_tags]
  
  def retrieve_all_tags
    if params[:q].nil? || params[:q]== '' || params[:q].split('').length < 3
      @metatags = []
    else
      @metatags = MetaInformation.find(:all,
        :select => "DISTINCT meta_information",
        :conditions => ['meta_information LIKE ?',"#{params[:q]}%"],
        :limit => 5, 
        :order => 'meta_information'
      )
    end
    respond_to do |format|
      format.xml { render :xml => @metatags }
#      format.html { render :xml => @users }
      format.js # user_search.js.erb
      format.json { render :json => @metatags }
    end
  end
end