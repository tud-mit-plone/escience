require 'digest/sha1'
#require 'net/http'
require 'open-uri'
require 'openssl'
require 'base64'
require 'rexml/document'
require 'xml-object'

class BbbController < ApplicationController

  before_filter :find_project, :find_user
  before_filter :authorize, :except => ['bbb_session', 'start_form','bbb_session_files']

  def start
    #First, test if meeting room already exists
    server = find_bbb_server
    create_bbb_session_or_redirect(server)
  end

  def start_form 
    #First, test if meeting room already exists
    if !(params[:server_url].nil?) && !(params[:server_url].empty?)
      bbb_server = BbbServer.new()
      bbb_server.url = params[:server_url]
      bbb_server.author = User.current
      @project.bbb_servers.push(bbb_server)
      
      bbb_server.save!
      server = bbb_server.url 
    end
    server = find_bbb_server if server.nil? || server.to_s.empty?
    create_bbb_session_or_redirect(server,params[:record_session?] == 'true')
  end
  
  def bbb_session
    @bbb = {} 
    @project_bbb_server = BbbServer.all(:include => :projects, :conditions => ["projects.id = ?", @project.id]) unless @project.nil?
    @project_bbb_server ||= []
    @bbb_server_running ||= {}
    @project_bbb_server.each do |srv|
      url = get_join_url_from_bbb_server(srv)
      @bbb_server_running[srv.url] = url
    end
    @bbb_server_running["default"] = get_join_url_from_bbb_server()
    respond_to do |format|
      format.html # session.html.erb
    end
  end

  def bbb_session_files
    server = find_bbb_server
    @bbb_session_files = []
    data = callapi(server,"getRecordings","meetingID=" + @project.identifier,true)
    data = callapi(server,"getRecordings",'',true)
    response = XMLObject.new(data) 

    if response.returncode == "SUCCESS"
      if response.recordings.recording.is_a?(Array)
        response.recordings.each do |element|
          logger.debug element
          @bbb_session_files << { :name => element.name.to_s, 
             :url => element.playback.format.url.to_s}
        end
      else
        @bbb_session_files << { :name => response.recordings.recording.name.to_s, 
             :url => response.recordings.recording.playback.format.url.to_s}
      end
    end
    respond_to do |format|
      format.html # bbb_session_files.html.erb
    end
  end 

  private

  def create_bbb_session_or_redirect(server,record=false)
    ok_to_join = false
    back_url = Setting.plugin_redmine_bbb['bbb_url'].empty? ? request.referer.to_s : Setting.plugin_redmine_bbb['bbb_url']

    moderatorPW = Digest::SHA1.hexdigest("root"+@project.identifier)
    attendeePW = Digest::SHA1.hexdigest("guest"+@project.identifier)
    
    data = callapi(server, "getMeetingInfo","meetingID=" + @project.identifier + "&password=" + moderatorPW, true)
    if data == false 
      redirect_to(back_url) 
      return 
    end
    doc = REXML::Document.new(data)
    data = callapi(server, "end","meetingID=" + @project.identifier + "&password=" + moderatorPW, true)
    if doc.root.elements['returncode'].text == "FAILED"
      #If not, we created it...
      if @user.allowed_to?(:bigbluebutton_start, @project)
        bridge = "77777" + @project.id.to_s
        bridge = bridge[-5,5]
        data = callapi(server, "create",
          "name=" + CGI.escape(@project.name) + 
          "&meetingID=" + @project.identifier + 
          "&attendeePW=" + attendeePW + 
          "&moderatorPW=" + moderatorPW + 
          "&logoutURL=" + back_url + 
          "&record=#{record == true ? true : false}" + 
          "&voiceBridge=" + bridge, true)
        ok_to_join = true
      end
    else
      moderatorPW = doc.root.elements['moderatorPW'].text
      ok_to_join = true
    end
    #Now, join meeting...
    if ok_to_join
      server = Setting.plugin_redmine_bbb['bbb_server'] if server.nil? 
      url = callapi(server, "join", "meetingID=" + @project.identifier + "&password="+ (@user.allowed_to?(:bigbluebutton_moderator, @project) ? moderatorPW : attendeePW) + "&fullName=" + CGI.escape(User.current.name), false)
      redirect_to url
    else
      redirect_to back_url
    end
  end

  def get_join_url_from_bbb_server(srv=bbb_default_server)
    logger.debug(srv)
    moderatorPW = Digest::SHA1.hexdigest("root"+@project.identifier)
    attendeePW = Digest::SHA1.hexdigest("guest"+@project.identifier)
    return callapi(srv.url, "join", "meetingID=" + @project.identifier + "&password="+ (@user.allowed_to?(:bigbluebutton_moderator, @project) ? moderatorPW : attendeePW) + "&fullName=" + CGI.escape(User.current.name), false, srv.server_salt.to_s)
  end      

  def callapi (server, api, param, getcontent, salt)
    tmp = api + param + salt
    checksum = Digest::SHA1.hexdigest(tmp)
    url = server + "/bigbluebutton/api/" + api + "?" + param + "&checksum=" + checksum
    logger.debug("#{url}")
    begin 
      if getcontent
        connection = open(url)
        connection.read
      else
        url
      end
    rescue Errno::ECONNREFUSED
      flash[:error] = "No connection to the server possible, please check selected url"
      return false 
    end

  end

  def find_bbb_server 
    return Setting.plugin_redmine_bbb['bbb_ip'].empty? ? Setting.plugin_redmine_bbb['bbb_server'] : Setting.plugin_redmine_bbb['bbb_ip']
  end

  def find_project
    # @project variable must be set before calling the authorize filter
    if params[:project_id]
       @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    User.current = find_current_user
    @user = User.current
  end

  def bbb_default_server
    return BbbServer.new(:url => find_bbb_server,:server_salt => Setting.plugin_redmine_bbb['bbb_salt'])
  end

  # Authorize the user for the requested action
  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project, :global => global)
    allowed ? true : deny_access
  end
    
end
