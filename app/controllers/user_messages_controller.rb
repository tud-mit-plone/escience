class UserMessagesController < ApplicationController

  EMAIL_REGEX=/(?:[a-z0-9!#\$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/

  include ApplicationHelper

  before_filter :is_author?, :only => [:update, :show, :destroy, :edit, :archive]
  before_filter :require_login, :only => [:index, :create, :update, :show, :sent_messages, :new, :destroy, :emptytrash, :edit, :archive]
  before_filter :get_reply_message,  :only => [:new, :create, :show]

  # GET /user_messages
  # GET /user_messages.xml
  def index
    get_directory_and_messages()
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_messages }
    end
  end

  def get_directory_and_messages
    dir = "received"
    if !params[:directory].nil?
      dir = case params[:directory]
        when "trash" then UserMessage.trash_directory
        when "sent" then UserMessage.sent_directory
        when "archive" then UserMessage.archive_directory
        when "received" then UserMessage.received_directory
        else ""
      end
      @directory = dir
    end
    msgs = UserMessage.find(:all, :conditions => ["author = :u AND directory = :dir",{:u => User.current.id, :dir => dir} ],:order => "created_at DESC")
    if msgs.class != Array && !msgs.nil?
      @user_messages ||= []
      @user_messages << msgs
    else
      @user_messages = msgs
    end
  end

  # GET /user_messages/1.xml
  def show
    @user_message = UserMessage.find(params[:id])
    @user_message.state = 0
    @user_message.save!

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user_message }
    end
  end

  def sent_messages
    msgs = UserMessage.find_by_user_id(User.current.id)
    if msgs.class != Array
      @user_messages ||= []
      @user_messages << msgs
    else
      @user_messages = msgs
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_messages }
    end
  end

  # GET /user_messages/new
  # GET /user_messages/new.xml
  def new
    @user_message = UserMessage.new
    if !@user_message_reply_mail.nil?
      @receivers = []
      @receivers += @user_message_reply_mail.receiver_list if !@user_message_reply_mail.receiver_list.nil?
      @receivers << @user_message_reply_mail.user if !@user_message_reply_mail.user.nil?
      @receivers << @user_message_reply_mail.receiver if !@user_message_reply_mail.receiver.nil?
      @receivers.uniq!
      @receivers.delete(User.current)
    else
      params.delete :reply
      if !params[:to].nil?
        @receivers = [User.find(params[:to])]
      end
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user_message }
    end
  end

  # GET /user_messages/1/edit
  def edit
    @user_message = UserMessage.find(params[:id])
  end

  # POST /user_messages
  # POST /user_messages.xml
  def create
    noerror = true
    notice = ""

    if (params[:user_message]["receiver"].empty? || params[:user_message]["subject"].empty? || params[:user_message]["body"].empty?)
      noerror = false;
      notice = l(:error_empty_message)
      @user_message_reply = notice
    else
      unless params[:user_message]["receiver"].nil?
        sent_users = []
        @receiver_arr = User.where(:id => params[:user_message]["receiver"].split(",").uniq)
        send_recv_list = params[:hide_receivers] == 'false'

        @receiver_arr.each do |recv|
          if recv.nil?
            @user_massage = UserMessage.new()
            flash[:notice] = l(:error_receiver_unknown)
            respond_to do |format|
              format.html { redirect_to(:action => 'new', :notice => 'Receiver not known') }
              format.xml  { render :xml => @user_message.errors, :status => :unprocessable_entity }
            end
            return
          end
          if @user_message.nil? || @user_message.new_record?
            @user_message = UserMessage.new()
            @user_message.body = convertHtmlToWiki(params[:user_message]["body"])
            @user_message.subject = params[:user_message]["subject"]
            @user_message.user = User.current
            @user_message.author = User.current.id
            @user_message.receiver_id = recv.id
            @user_message.state = 3
            @user_message.directory = UserMessage.sent_directory
            @user_message.parent = @user_message_reply_mail
            noerror &= @user_message.save
          end
          noerror &= @user_message.generate_sent_receiver_copy(recv.id, send_recv_list ? @receiver_arr.collect(&:id) : nil)
          sent_users << recv.id
        end

        if sent_users.length > 1
          @user_message.receiver_list = sent_users
          @user_message.receiver_id = nil
          @user_message.save
        end

      end
    end
    if (!noerror)
      flash[:notice] = notice
      respond_to do |format|
        format.html { redirect_to(request.referer) }
        format.xml  { render :xml => @user_message.errors, :status => :unprocessable_entity }
      end
    else
      respond_to do |format|
        if !params[:reply_mail].nil? && !params[:reply_mail].empty?
          reply_mail = UserMessage.find(params[:reply_mail])
          reply_mail.state = 4
          reply_mail.save
        end
        flash[:notice] = l(:text_message_sent_done)
        format.html { redirect_to(request.referer) }
        format.js { render :partial => 'update' }
        format.xml  { render :xml => @user_message, :status => :created, :location => @user_message }
      end
    end
  end

  # PUT /user_messages/1
  # PUT /user_messages/1.xml
  def update
    @user_message = UserMessage.find(params[:id])

    respond_to do |format|
      if @user_message.update_attributes(params[:user_message])
        format.html { redirect_to(@user_message, :notice => 'UserMessage was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user_message.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @user_message = UserMessage.find(params[:id])
    if !params[:directory].nil? && params[:directory] == UserMessage.trash_directory
      @user_message.destroy
    else
      @user_message.state = 2
      @user_message.directory = UserMessage.trash_directory
      @user_message.save
    end
    get_directory_and_messages()

    respond_to do |format|
      format.html { redirect_to(request.referer, :notice => l(:text_message_delete_done)) }
      format.js  { @update_messages = true; render :partial => 'update'}
      format.xml  { head :ok }
    end
  end

  def archive
    @user_message = UserMessage.find(params[:id])
    @user_message.directory = UserMessage.archive_directory
    if (@user_message.state == 2)
      @user_message.state = 0
    end
    @user_message.save
    get_directory_and_messages()

    respond_to do |format|
      format.html { redirect_to(request.referer, :notice => l(:text_message_archive_done)) }
      format.js  { @update_messages = true; render :partial => 'update'}
      format.xml  { head :ok }
    end
  end

  def emptytrash
    del_msg = UserMessage.destroy_all("author=#{User.current.id} AND state=2")

    if del_msg.class != Array
      _del_msg ||= []
      _del_msg << del_msg
      del_msg = _del_msg
    end
    error = false
    del_msg.each do |e|
      if !e.destroyed?
        error = true
      end
    end

    respond_to do |format|
      if !error
        format.html { redirect_to(request.referer, :notice => l(:text_message_emptytrash_done)) }
      else
        format.html { redirect_to(request.referer, :notice => l(:text_message_emptytrash_error)) }
      end
      format.xml  { head :ok }
    end
  end

  def history_messages
    history = UserMessage.where(:id => params[:id]).where(:author => User.current)
    respond_to do |format|
      format.json render :json => history
    end
  end

  private

  def is_author?
    @user_message = UserMessage.find(params[:id])
    if !(@user_message.read_attribute("author").to_i == User.current.id.to_i)
      render_403
      return false
    end
    return true
  end

  def get_reply_message
    @user_message_reply_mail = UserMessage.where(:id => params[:reply], :author => User.current.id).first
  end

    # State:    0 read message
    #           1 new message
    #           2 deleted message
    #           3 sent message (for getting Sent-Message)
    #           4 answered message
end
