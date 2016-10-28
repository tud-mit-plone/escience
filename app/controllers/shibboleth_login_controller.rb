class ShibbolethLoginController < ApplicationController
  before_filter :require_admin

  def show
    @settings = Setting.shibboleth_login
  end

  def update
    Setting.shibboleth_login = params[:settings]
    redirect_to :action => 'show'
  end

end
