RedmineApp::Application.routes.draw do
  resources :appointments
  match 'appointments/:id', :to => 'appointments#destroy', :via => :delete
  match 'calendar', :to => 'calendars#show_user_calendar', :via => [:get, :post]
end