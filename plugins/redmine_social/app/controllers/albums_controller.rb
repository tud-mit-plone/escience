class AlbumsController < ApplicationSocialController

  before_filter :require_login
  before_filter :project_album_if_visible  
  before_filter :find_user, :only => [:new, :edit, :index]
  before_filter :require_current_user, :only => [:new, :edit, :update, :destroy, :create]
  before_filter :get_albums, :only => [:index, :new]

  # GET /albums/1
  # GET /albums/1.xml
  def show
    @album = Album.find(params[:id])
    #update_view_count(@album) if User.current && User.current.id != @album.user_id
    @album_photos = @album.photos.paginate(:page => params[:page], :per_page => 6)
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @album }
    end
  end
  
  # GET /albums/new
  # GET /albums/new.xml
  def new
    @album = Album.new(params[:album])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @album }
    end
  end

  # GET /albums/1/edit
  def edit
    @album = Album.find(params[:id])
  end

  # POST /albums
  # POST /albums.xml
  def create
    @album = Album.new(params[:album])
    @album.user_id = User.current.id
    @album.container = @project
    
    respond_to do |format|
      if @album.save
        if @project 
          if params[:commit] == 'only_create'
            flash[:notice] = l(:album_was_successfully_created)
            #format.html { redirect_to({:action => 'edit', :user_id => User.current.id, :project_id => @project.id, :album_id => @album.id})}
            format.html { redirect_to({:action => 'edit', :user_id => User.current.id, :project_id => @project.id, :id => @album.id})}
          else
            #format.html { redirect_to({:controller => 'photos', :action => 'new', :user_id => User.current.id, :project_id => @project.id, :album_id => @album.id})}
            format.html { redirect_to({:controller => 'photos', :action => 'new', :user_id => User.current.id, :project_id => @project.id, :id => @album.id})}
          end
        else
          if params[:commit] == 'only_create'
            flash[:notice] = l(:album_was_successfully_created)
            #format.html { redirect_to({:action => 'edit', :user_id => User.current.id, :album_id => @album.id})}
            format.html { redirect_to({:action => 'edit', :user_id => User.current.id, :id => @album.id})}
          else
            #format.html { redirect_to({:controller => 'photos', :action => 'new', :user_id => User.current.id, :album_id => @album.id})}
            format.html { redirect_to({:controller => 'photos', :action => 'new', :user_id => User.current.id, :id => @album.id})}
          end
        end
      else
        format.html { render :action => 'new' }
      end 
    end
  end

  def index         
    respond_to do |format|
      if @albums.empty?
        format.html { redirect_to({:action => 'new'})}
      else 
        format.html{}
      end
    end
  end

  # PUT /albums/1
  # PUT /albums/1.xml
  def update
    
    respond_to do |format|
      if @album.update_attributes(params[:album])
        if @project 
          if params[:go_to] == 'only_create'
            flash[:notice] = l(:album_updated)
            #format.html { redirect_to({:action => 'edit', :user_id => User.current.id, :project_id => @project.id, :album_id => @album.id})}
            format.html { redirect_to({:action => 'edit', :user_id => User.current.id, :project_id => @project.id, :id => @album.id})}
          else
            #format.html { redirect_to({:controller => 'photos', :action => 'new', :user_id => User.current.id, :project_id => @project.id, :album_id => @album.id})}
            format.html { redirect_to({:controller => 'photos', :action => 'new', :user_id => User.current.id, :project_id => @project.id, :id => @album.id})}
          end
        else
          if params[:go_to] == 'only_create'
            flash[:notice] = l(:album_updated)
            #format.html { redirect_to({:action => 'edit', :user_id => User.current.id, :album_id => @album.id})}
            format.html { redirect_to({:action => 'edit', :user_id => User.current.id, :id => @album.id})}
          else
            #format.html { redirect_to({:controller => 'photos', :action => 'new', :user_id => User.current.id, :album_id => @album.id})}
            format.html { redirect_to({:controller => 'photos', :action => 'new', :user_id => User.current.id, :id => @album.id})}
          end
        end
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @album.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /albums/1
  # DELETE /albums/1.xml
  def destroy  
    @album.destroy

    if @project 
      respond_to do |format|
        format.html { redirect_to :action => 'index', :project => @project }
        format.xml  { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to :action => 'index', :user => User.current }
        format.xml  { head :ok }
      end
    end
  end
  
  def add_photos
    
  end
  
  def photos_added
    @album.photo_ids = params[:album][:photos_ids].uniq
    redirect_to user_albums_path(User.current)
    flash[:notice] = l(:album_added_photos)
  end

private 

  def get_albums
    if(params[:user_id])
      @albums = User.find(params[:user_id]).albums
    elsif(params[:project_id])
      @albums = @project.albums
    else
      @albums = @user.albums
    end
    @container = {}
    unless @album.container.nil? 
      @albums.each do |album|
        container_name = album.container.name == User.current.mail ? l(:label_project_private) : album.container.name
        @container[container_name] ||= []
        @container[container_name] << album
      end 
    end
  end

  def project_album_if_visible
    @album = Album.find(params[:id]) if params[:id]
    @project = Project.find(params[:project_id]) unless params[:project_id].nil?
    
    unless ((@project.nil? || @project.visible?) && (@album.nil? || @album.container.nil? || @album.container.visible?))
      render_403
    end
  end
end
