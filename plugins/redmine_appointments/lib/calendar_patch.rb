module Plugin
module RedmineAppointmentExtension

  events = Proc.new {
    amount = Issue.where('(start_date <= ? AND due_date >= ?) AND ((assigned_to_id IS NULL AND author_id=?) OR assigned_to_id=?)',Date.today.to_s,Date.today.to_s,User.current.id,User.current.id).count
    appointments = Appointment.getAllEventsWithCycle
    amount += appointments.count
  }
  
  Redmine::MenuManager.map(:account_menu).delete(:calendar_all)
  Redmine::MenuManager.map(:account_menu).push :calendar_all, { :controller => 'calendars', :action => 'show', :sub => 'calendar_all'}, :caption => {:value_behind => events, :text => :label_calendar }

  module CalendarsController
    module ClassMethods
    end
    module InstanceMethods
    end

    def self.included(receiver)
      receiver.class_eval do
      
        helper Appointment::AppointmentsHelper
        self.prepend_view_path( "#{Rails.root}/plugins/redmine_appointments/app/views/appointments/index.html.erb")
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
            events = []
            events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                                    :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?)) #{'AND creator='+User.current.id.to_s if session[:current_view_of_eScience]=="0"}", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                                    )
            events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])
            
          end
          events += Appointment.getAllEventsWithCycle(@calendar.startdt,@calendar.enddt)
          @listOfDaysBetween = Appointment.getListOfDaysBetween(@calendar.startdt,@calendar.enddt)
          @calendar.events = events
          @appointment = Appointment.new
          @available_watchers = (@appointment.watcher_users).uniq

          respond_to do |format|
            format.html { render :controller=> 'calendars',:action => 'show', :layout => false if request.xhr? }
            format.js { 
              render :partial => 'update' 
            }
          end
        end
      end
    end
  end
end
end