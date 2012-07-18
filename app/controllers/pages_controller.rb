class PagesController < ApplicationController

unloadable
layout Proc.new { |_| "base"}

rescue_from ActionView::MissingTemplate do |exception|
  if exception.message =~ %r{Missing template #{content_path}}
    raise ActionController::RoutingError, "No such page: #{params[:id]}"
  else
    raise exception
  end
end

def show
  @user = session[:user].nil? ? User.new : session[:user]
  render :template => current_page
end

protected

  def current_page
    "#{content_path}#{clean_path}"
  end

  def clean_path
    path = Pathname.new "/#{params[:id]}"
    path.cleanpath.to_s[1..-1]
  end

  def content_path
    "pages/"
  end
end