  RedmineApp::Application.routes.draw do
    match 'blogs/new', :controller => 'blogs', :action => 'new', :via => [:post, :get]
    match 'blogs/index', :controller => 'blogs',:action => 'index', :via => :get
    match 'blogs/show/:id', :controller => 'blogs',:action => 'show', :via => :get
    match 'blogs/edit/:id', :controller => 'blogs',:action => 'edit', :via => [:get,:post,:put]

    match 'blogs/gettaglist', :controller => 'blogs', :action => 'get_tag_list'
    match 'blogs/preview', :controller => 'blogs', :action => 'preview'
    match 'blogs/showbytag/:id', :controller => 'blogs', :action => 'show_by_tag'
    match 'blogs/destroy/:id', :controller => 'blogs', :action => 'destroy'
    match 'blogs/addcomment', :controller => 'blogs', :action => 'add_comment'
    match 'blogs/destroycomment/:comment_id', :controller => 'blogs', :action => 'destroy_comment'
  end
