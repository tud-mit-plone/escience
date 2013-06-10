module Plugin
module RedmineAppointmentExtension

  events = Proc.new {
    today = Date.today
    visible_issues = Issue.visible
    amount = visible_issues.empty? ? 0 : Issue.find(:all, :conditions => ["((due_date = ?) OR (start_date = ?)) AND id IN (#{visible_issues.map {|e| e.id}.join(', ')})", today, today]).count
    amount += Appointment.getAllEventsWithCycle().count
    #.where('(start_date <= ? AND due_date >= ?) AND ((assigned_to_id IS NULL AND author_id=?) OR assigned_to_id=?)',Date.today.to_s,Date.today.to_s,User.current.id,User.current.id).count
#    appointments = Appointment.getAllEventsWithCycle
#    amount += appointments.count
  }
  
  Redmine::MenuManager.map(:account_menu).delete(:calendar_all)
  Redmine::MenuManager.map(:account_menu).push :calendar_all, { :controller => 'calendars', :action => 'show_user_calendar', :sub => 'calendar_all'}, :caption => {:value_behind => events, :text => :label_calendar }

  module CalendarsController
    module ClassMethods
    end
    module InstanceMethods
    end

    def self.included(receiver)
      receiver.class_eval do
      
        helper Appointment::AppointmentsHelper
        before_filter :require_login, :only => [:show, :index,:show_user_calendar, :get_events_on_current_day]
        before_filter :find_optional_project, :except => [:show_user_calendar, :get_events_on_current_day]
        
        def get_events_on_current_day
          today = Date.today
          events = Issue.find(:all, :conditions => ["((due_date = ?) OR (start_date = ?)) AND id IN (#{Issue.visible.map {|e| e.id}.join(', ')})", today, today])
          events += Appointment.getAllEventsWithCycle(today, today)
          event_list = '<table cellspacing="0" cellpadding="0"><tr>'
          event_list += events.map{ |e| 
            if (e[:start_date].strftime("%H").to_i != 0 || e[:start_date].strftime("%M").to_i != 0)
              '<td>'+format('%02d',e[:start_date].strftime("%H").to_i) + ':' + format('%02d',e[:start_date].strftime("%M").to_i) + '</td><td style="padding-left:5px;">&nbsp;</td><td>' + e[:subject]+'</td>'
            else 
              '<td colspan="2">&nbsp;</td><td>' + e[:subject] + '</td>'
            end
          }.join('</tr><tr>')
          event_list += "</tr></table>"
          respond_to do |format|
            format.html { render :xml => event_list}
            format.xml { render :xml => event_list}
            format.js # user_search.js.erb
            format.json { render :json => event_list}
          end
        end

        def show_user_calendar
          return render_403 unless User.current.allowed_to?(:appointments_create,nil, {:global => true}) || User.current.admin?
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

          events ||= []
          if params[:show].nil?
              params[:show] = User.current.pref[:calendar_params]
          else
              User.current.pref[:calendar_params] = params[:show]
              User.current.pref.save
          end
          @show_params = {}
       
          if params.nil? || (params[:show].nil? || params[:show][:community_issues] )
            new_events = get_community_issues_for_calendar()
            events += new_events unless new_events.nil? 
            @show_params [:community_issues] = true
          end
          if params.nil? || (params[:show].nil?) || params[:show][:private_issues]
            new_events = get_private_issues_for_calendar()
            events += new_events unless new_events.nil? 
            @show_params [:private_issues] = true
          end
          if params.nil? || (params[:show].nil?) || params[:show][:watched_issues]
            new_events = get_watched_issues_for_calendar()
            events += new_events unless new_events.nil? 
            @show_params [:watched_issues] = true
          end
          if params.nil? || (params[:show].nil?) || params[:show][:watched_appointments]
            new_events = get_watched_appointments_for_calendar()
            events += new_events unless new_events.nil? 
            @show_params [:watched_appointments] = true
          end
          @listOfDaysBetween = getListOfDaysBetween(events,@calendar.startdt, @calendar.enddt)
          @listOfDaysBetween.merge!(Appointment.getListOfDaysBetween(@calendar.startdt,@calendar.enddt))
          if params.nil? || (params[:show].nil?) || params[:show][:private_appointments] 
            new_appointments = get_user_appointments()
            events += new_appointments unless new_appointments.nil? 
            @show_params [:private_appointments] = true
          end

          @calendar.events = events
          @appointment = Appointment.new
          @available_watchers = (@appointment.watcher_users).uniq
          respond_to do |format|
            format.html { render :controller=> 'calendars',:action => 'show_user_calendar', :layout => false if request.xhr? }
            format.js { render :partial => 'update' }
          end
        end
        private 

        def get_private_issues_for_calendar()
          @query.group_by = nil
          if @query.valid? &&  !(@project.nil?)
            events = []
            events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?)) AND creator=?", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt,creator])  
            events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])    
          end

          return events 
        end

        def get_community_issues_for_calendar()
          @query.group_by = nil
          if @query.valid? 
            events = []
            tp = @project 
            Project.find(:all).select{|p| p.visible?}.each do |p| 
              @project = p 
              events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                                      :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                                      )
              events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt]) 
            end
          end
          @project = tp 
          return events 
        end

        def get_watched_issues_for_calendar()
          return Issue.watched_by(User.current.id) 
        end

        def get_user_appointments() 
          events = Appointment.getAllEventsWithCycle(@calendar.startdt,@calendar.enddt)
          return events
        end

        def get_watched_appointments_for_calendar()
          return Appointment.watched_by(User.current.id)
        end

        def getListOfDaysBetween(events, startdt=Date.today,enddt=Date.today)
          listOfDaysBetween = {}
          events.each do |event|
            if event[:start_date] >= startdt && event[:start_date] < enddt && event[:start_date] != event[:due_date] && !event[:due_date].nil?
              currentDate = event[:start_date].to_date.to_time + 1.day
              while currentDate < event[:due_date] && currentDate <= enddt
                if listOfDaysBetween[currentDate.to_date.to_s].nil?
                  listOfDaysBetween[currentDate.to_date.to_s] = [event]
                else
                  listOfDaysBetween[currentDate.to_date.to_s] << event
                end
                currentDate += 1.day
              end
            end
          end
          return listOfDaysBetween
        end
        
      end
    end
  end
end
end
