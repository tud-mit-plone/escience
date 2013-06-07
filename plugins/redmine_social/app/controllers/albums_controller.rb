class AlbumsController < ApplicationSocialController

  before_filter :require_login
  before_filter :find_user, :only => [:new, :edit, :index]
  before_filter :require_current_user, :only => [:new, :edit, :update, :destroy, :create]

  # GET /albums/1
  # GET /albums/1.xml
  def show
    @album = Album.find(params[:id])
    #update_view_count(@album) if User.current && User.current.id != @album.user_id
    @album_photos = @album.photos.paginate(:page => params[:page], :per_page => 1)
    
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
    
    respond_to do |format|
      if @album.save
        if params[:go_to] == 'only_create'
          flash[:notice] = l(:album_was_successfully_created) 
          format.html { redirect_to(user_photo_manager_index_path(User.current)) }       
        else
          format.html { redirect_to(new_user_album_photo_path(User.current, @album)) }
        end
      else
        format.html { render :action => 'new' }
      end 
    end
  end

  def index 
    @albums = User.find(params[:user_id]).albums
    respond_to do |format|
      format.html{}
    end
  end

  # PUT /albums/1
  # PUT /albums/1.xml
  def update
    @album = Album.find(params[:id])

    respond_to do |format|
      if @album.update_attributes(params[:album])
        if params[:go_to] == 'only_create'
          flash[:notice] = l(:album_updated)
          format.html { redirect_to(user_album_path(User.current, @album)) }
        else
          format.html { redirect_to(new_user_album_photo_path(User.current, @album)) }
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
    @album = Album.find(params[:id])
    @album.destroy

    respond_to do |format|
      format.html { redirect_to user_photo_manager_index_path(User.current) }
      format.xml  { head :ok }
    end
  end
  
  def add_photos
    @album = Album.find(params[:id])
  end
  
  def photos_added
    @album = Album.find(params[:id])
    @album.photo_ids = params[:album][:photos_ids].uniq
    redirect_to user_albums_path(User.current)
    flash[:notice] = l(:album_added_photos)
  end
  
end
