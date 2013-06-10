class AppointmentsController < ApplicationController
  unloadable
#  before_filter :authorize
  before_filter :find_appointment, :only => [:show, :edit, :update]

  helper :journals
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  include ApplicationHelper

  def index
    @appointments = Appointment.visible
    respond_to do |format|
      format.html { render :template => 'appointments/index', :layout => !request.xhr? }
    end
  end
  
  def show    
    respond_to do |format|
      format.html {render :template => 'appointments/show'}
    end
  end

  def new
    @appointment = Appointment.new
    @available_watchers = (@appointment.watcher_users).uniq
    respond_to do |format|
      format.html { render :action => 'new', :layout => !request.xhr? }
      format.js { render :partial => 'update_form' }
    end
  end

  def edit
    respond_to do |f| 
      f.html {render :action => 'edit'}
    end
  end

  def update
    params[:appointment][:description] = convertHtmlToWiki(params[:appointment][:description])
    start_date = params[:appointment][:start_date] == "" ? nil : params[:appointment][:start_date]
    due_date = params[:appointment][:due_date] == "" ? nil : params[:appointment][:due_date]
    params[:appointment][:start_date] = Date.strptime(start_date,::I18n.t("date.formats.default")).to_s if start_date
    params[:appointment][:due_date] = Date.strptime(due_date,::I18n.t("date.formats.default")).to_s if (due_date && due_date != "00:00")
    params[:appointment][:start_date] += " " + params[:appointment][:start_time]
    params[:appointment][:due_date] += " " + params[:appointment][:due_time] if (due_date && due_date != "00:00")
    params[:appointment].delete(:start_time)
    params[:appointment].delete(:due_time)
    @referer = params[:referer]
    @appointment.save_attachments(params[:attachments] || (params[:appointment] && params[:appointment][:uploads]))
    @appointment.attributes = params[:appointment]
    @appointment.user = User.current
    if @appointment.save
      flash[:notice] = l(:notice_appointment_successful_create)    
      respond_to do |format|
        format.html {
          if params[:continue]
            redirect_to({ :action => 'edit'})
          else
            if @referer.nil?
              redirect_to({ :action => 'show', :id => @appointment.id })
            else
              redirect_to(@referer)
            end
          end
        }
      end
      return
    else
      flash[:error] = l(:notice_appointment_fail_create)
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@appointment) }
      end
    end
  end

  def create
    @appointment = Appointment.new
    params[:appointment][:description] = convertHtmlToWiki(params[:appointment][:description])
    start_date = params[:appointment][:start_date].empty? ? nil : params[:appointment][:start_date]
    due_date = params[:appointment][:due_date].empty? ? nil : params[:appointment][:due_date]
    begin
      params[:appointment][:start_date] = Date.strptime(start_date,::I18n.t("date.formats.default")).to_s if start_date
      params[:appointment][:due_date] = Date.strptime(due_date,::I18n.t("date.formats.default")).to_s if due_date
    rescue => e
      logger.error(e.message)
    end
    params[:appointment][:start_date] += " " + params[:appointment][:start_time] unless params[:appointment][:start_date].empty?
    params[:appointment][:due_date] += " " + params[:appointment][:due_time] unless params[:appointment][:due_date].empty?
    params[:appointment].delete(:start_time)
    params[:appointment].delete(:due_time)
    @appointment.save_attachments(params[:attachments] || (params[:appointment] && params[:appointment][:uploads]))
    @appointment.attributes = params[:appointment]
    @appointment.user = User.current
    if @appointment.save
      flash[:notice] = l(:notice_appointment_successful_create)
      respond_to do |format|
        format.html {
          if params[:continue]
            render :action => 'new'
          else
            redirect_to({ :action => 'show', :id => @appointment.id })
          end
        }
        format.js {
          if params[:view] == 'calendar'
            redirect_to({:controller => 'calendars', :action => 'show_user_calendar', :format => 'js', :new => params[:continue]})
          else
            render :action => 'new'
          end
        }
      end
      return
    else
      flash[:error] = l(:notice_appointment_fail_create)
      render_attachment_warning_if_needed(@appointment)
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@appointment) }
        format.js {
          if params[:view] == 'calendar'
            render :partial => 'update'
          else
            render :action => 'new'
          end
        }
      end
    end
  end 
  
  def destroy
    if Appointment.find(params[:id]).destroy
      @appointment = Appointment.new
      @available_watchers = (@appointment.watcher_users).uniq
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@appointment) }
        format.js {
          if params[:view] == 'calendar'
            redirect_to({:controller => 'calendars', :action => 'show_user_calendar', :format => 'js'})
          else
            render :action => 'new'
          end
        }
      end
    else
      render_404
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
private

  def find_appointment
    @referer = request.referer
    @appointment = Appointment.find(params[:id])
    unless @appointment.visible?
      deny_access
      return
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
