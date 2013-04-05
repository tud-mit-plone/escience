RedmineApp::Application.routes.draw do
  resources :appointments
  match 'appointments/:id', :to => 'appointments#destroy', :via => :delete
end