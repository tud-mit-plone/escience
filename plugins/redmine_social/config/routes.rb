RedmineApp::Application.routes.draw do
  
  match 'attachments/thumbnail/:id(/:size)', :controller => 'attachments', :action => 'thumbnail', :id => /\d+/, :via => :get, :size => /\d+/, :as => :thumbnail_attachment

# automatic insertion for ads model
  resources :ads 
# automatic insertion for photo_manager model
  resources :photo_manager
# automatic insertion for friendship model
  get '/friendships.xml' => 'friendships#index', :as => :friendships_xml, :format => 'xml'
  get '/friendships' => 'friendships#index', :as => :friendships

  get 'manage_photos' => 'photos#manage_photos', :as => :manage_photos
  post 'create_photo.js' => 'photos#create', :as => :create_photo, :format => 'js'

  match 'my/render_block/:blockname', :controller => 'my', :action => 'render_block', :via => :get, :blockname => /\w+/
  match 'my/interest_search', :controller => 'my', :action => 'interest_search', :via => :get
  match 'my/skill_search', :controller => 'my', :action => 'skill_search', :via => :get

  resources :projects do 
    resources :photos do
      post 'add_comment', :action => :add_comment
    end
    resources :albums do
     get 'show', :action => :show 
    end
  end

  resources :users do
    member do 
      get 'statistics'
      get 'crop_profile_photo'
      put 'crop_profile_photo'
      get 'upload_profile_photo'
      put 'upload_profile_photo'
      post 'upload_profile_photo.js' => 'users#upload_profile_photo', :as => :upload_profile_photo, :format => 'js'
    end
    resources :friendships do
      collection do
        get :accepted
        get :pending
        get :denied
        get :write_message
      end
      member do
        put :accept
        put :deny
      end
    end
    resources :photos do
      get 'page/:page', :action => :index, :on => :collection
    end
  resources :albums do
	resources :photos do
	  collection do
	    post :swfupload
	    get :slideshow
	  end
	end
  end
  end

  controller :comments do 
    post '/comments/create', :action => :create_general_comment, :as => 'create_general_comments'
  end
  resources :photos do
    post 'add_comment', :action => :add_comment
  end
  resources :albums do
    get 'show', :action => :show 
  end
  resources :group_invitations, :except => [:show, :new, :edit, :update] do 
      member do 
        post 'create', :action => :create 
        post 'selection', :action => :selection
      end
  end
  match '/qr_gen(/:p_url)',:controller => 'application', :action => 'generate_qr_code', as: :generate_qr_code, :method => :get
  match '/userSessionScope/(:scope_select)',:controller => 'application', :action => 'set_user_session_scope',:scope_select => /\d+/, as: :set_user_session_scope, :method => [:post,:get]
end

