RedmineApp::Application.routes.draw do
  match 'bbb', :controller => :bbb, :action => :start 
  match 'projects/:project_id/bbb/start_form', :controller => :bbb, :action => :start_form, :via => :POST 
  match 'projects/:project_id/bbb/bbb_session', :controller => :bbb, :action => :bbb_session, :via => :GET
  match 'projects/:project_id/bbb/bbb_session_files', :controller => :bbb, :action => :bbb_session_files, :via => :GET
end