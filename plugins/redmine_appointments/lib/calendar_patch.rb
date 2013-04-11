module Plugin
module RedmineAppointmentExtension
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
          appointments = Appointment.visible
          events += appointments
          @listOfDaysBetween = {}
          appointments.each do |appointment|
            if appointment[:cycle] == Appointment::CYCLE_WEEKLY
              repeated_day = appointment[:start_date]+7.day
              while repeated_day < @calendar.enddt && repeated_day <= appointment[:due_date]
                event = appointment.clone
                event[:start_date] = repeated_day
                events += [event]
                repeated_day += 7.day
              end
            elsif appointment[:cycle] == Appointment::CYCLE_MONTHLY
              repeated_day = appointment[:start_date]+1.month
              while repeated_day < @calendar.enddt
                event = appointment.clone
                event[:start_date] = repeated_day
                events += [event]
                repeated_day = repeated_day+1.month
              end
            elsif appointment[:start_date] >= @calendar.startdt && appointment[:start_date] < @calendar.enddt && appointment[:start_date] != appointment[:due_date] && !appointment[:due_date].nil?
              currentDate = appointment[:start_date].to_date.to_time + 1.day
              while currentDate < appointment[:due_date] && currentDate <= @calendar.enddt
                @listOfDaysBetween[currentDate.to_date.to_s] ||= appointment
                currentDate += 1.day
              end
            end
          end
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