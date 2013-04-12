require 'redmine'

Rails.configuration.to_prepare do
  require 'calendar_patch'
  CalendarsController.send(:include, ::Plugin::RedmineAppointmentExtension::CalendarsController)
end

Redmine::Plugin.register :redmine_appointments do
  name 'Redmine Appointments plugin'
  author 'Mathias Puerzl'
  description 'This is a plugin for Redmine to create appointments that don\'t need a connection to a project.'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'https://escience.htwk-leipzig.de'

  activity_provider :appointments, :default => false, :class_name => ['Appointment']
  project_module :user_calendar do 
    permission :appointments_create, :calendars => :show_user_calendar
  end
end
