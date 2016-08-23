module Plugin
module RedmineAppointmentExtension

  Redmine::MenuManager.map(:private_menu).delete(:calendar_all)
  Redmine::MenuManager.map(:private_menu).push :calendar_all, { :controller => 'calendars', :action => 'show_user_calendar', :sub => 'calendar_all'}, :caption => {:text => :label_calendar }, :html => {:class => "icon icon-calendar"}

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
          if params.nil? || (params[:show].nil?) || params[:show][:community_appointments]
            new_events = get_community_appointments_for_calendar()
            events += new_events unless new_events.nil?
            @show_params [:community_appointments] = true
          end
          if params.nil? || (params[:show].nil?) || params[:show][:watched_appointments]
            new_events = get_watched_appointments_for_calendar()
            events += new_events unless new_events.nil?
            @show_params [:watched_appointments] = true
          end
          if params.nil? || (params[:show].nil?) || params[:show][:private_appointments]
            new_appointments = get_user_appointments()
            events += new_appointments unless new_appointments.nil?
            @show_params [:private_appointments] = true
          end
          @listOfDaysBetween = getListOfDaysBetween(events, @calendar.startdt, @calendar.enddt)

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

        def get_community_appointments_for_calendar()
          events = Appointment.getAllEventsWithResolvedCycles(Appointment.non_private, @calendar.startdt, @calendar.enddt)
          return events
        end

        def get_user_appointments()
          events = Appointment.getAllEventsWithResolvedCycles(Appointment.own, @calendar.startdt, @calendar.enddt)
          return events
        end

        def get_watched_appointments_for_calendar()
          events = Appointment.getAllEventsWithResolvedCycles(Appointment.watched, @calendar.startdt, @calendar.enddt)
          return events
        end

        def getListOfDaysBetween(events, startdt=Date.today,enddt=Date.today)
          listOfDaysBetween = {}
          events.each do |event|
            next if event[:start_date].nil? || event[:due_date].nil?
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
