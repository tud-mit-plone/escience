class AdsController < ApplicationController
  unloadable
  before_filter :require_login
  before_filter :require_admin  

  # GET /ads
  # GET /ads.xml
  def index
    @search = Ad.search(params[:search])
    @search.meta_sort ||= 'created_at.desc'    
    @ads = @search.paginate(:page => params[:page], :per_page => 15)
    logger.info("#{@search.class}")

    respond_to do |format|
      format.html
    end
  end

  # GET /ads/1
  # GET /ads/1.xml
  def show
    @ad = Ad.find(params[:id])

    respond_to do |format|
      format.html 
    end
  end

  # GET /ads/new
  def new
    @ad = Ad.new
  end

  # GET /ads/1;edit
  def edit
    @ad = Ad.find(params[:id])
  end

  # POST /ads
  # POST /ads.xml
  def create
    @ad = Ad.new(params[:ad])

    respond_to do |format|
      if @ad.save
        flash[:notice] = :ad_was_successfully_created
        format.html { redirect_to ad_url(@ad) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /ads/1
  # PUT /ads/1.xml
  def update
    @ad = Ad.find(params[:id])

    respond_to do |format|
      if @ad.update_attributes(params[:ad])
        flash[:notice] = :ad_was_successfully_updated.l
        format.html { redirect_to ad_url(@ad) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /ads/1
  # DELETE /ads/1.xml
  def destroy
    @ad = Ad.find(params[:id])
    @ad.destroy

    respond_to do |format|
      format.html { redirect_to ads_url }
      format.xml  { head :ok }
    end
  end
end
