RedmineApp::Application.routes.draw do
  resources :appointments
  match 'appointments/:id', :to => 'appointments#destroy', :via => :delete
  match 'calendar', :to => 'calendars#show_user_calendar', :via => [:get, :post]
  match 'get_events_on_current_day', :controller => 'calendars', :action => 'get_events_on_current_day'
end