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

class FilesController < ApplicationController
  menu_item :files

  before_filter :find_project_by_project_id
  before_filter :authorize

  helper :sort
  include SortHelper

  def index
    sort_init 'filename', 'asc'
    sort_update 'filename' => "#{Attachment.table_name}.filename",
                'created_on' => "#{Attachment.table_name}.created_on",
                'size' => "#{Attachment.table_name}.filesize",
                'downloads' => "#{Attachment.table_name}.downloads"

    @containers = [ Project.find(@project.id, :include => :attachments, :order => sort_clause)]
    @containers += @project.versions.find(:all, :include => :attachments, :order => sort_clause).sort.reverse
    @versions = @project.versions.sort
    render :layout => !request.xhr?
  end

  def new
    @versions = @project.versions.sort
  end

  def create
    container = (params[:version_id].blank? ? @project : @project.versions.find_by_id(params[:version_id]))
    attachments = Attachment.attach_files(container, params[:attachments])
    render_attachment_warning_if_needed(container)
    render_attachment_notice_if_upload_failed(attachments)
    
    messages = flash.to_hash
    @message = messages[:notice]
    flash.clear

    if !attachments.empty? && !attachments[:files].blank? && Setting.notified_events.include?('file_added')
      Mailer.attachments_added(attachments[:files]).deliver
    end
    errors = (attachments[:files].empty? && attachments[:unsaved].empty?) ? [l(:no_file_given)] : []
    attachments[:errors].each do |error|
      error.each do |k,v| 
        errors << l(k) + " #{v.first}" if (k != :base)
        errors << v.flatten if (k == :base)
      end
    end 
    if errors.empty?
      respond_to do |format|
        format.html {redirect_to project_files_path(@project)}
        format.js { 
          sort_init 'filename', 'asc'
          sort_update 'filename' => "#{Attachment.table_name}.filename",
                      'created_on' => "#{Attachment.table_name}.created_on",
                      'size' => "#{Attachment.table_name}.filesize",
                      'downloads' => "#{Attachment.table_name}.downloads"
      
          @containers = [ Project.find(@project.id, :include => :attachments, :order => sort_clause)]
          @containers += @project.versions.find(:all, :include => :attachments, :order => sort_clause).sort.reverse
          render :partial => 'update_attachment'
        }
      end
    else
      respond_to do |format|
        format.html {redirect_to project_files_path(@project)}
        format.json {
          render :js => "$.notification({ message:'#{errors.join('\\n')}', type:'error' })";
        }
      end
    end
  end
end
