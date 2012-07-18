class UserMessagesController < ApplicationController

  EMAIL_REGEX=/(?:[a-z0-9!#\$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/

  before_filter :is_author?, :only => [:update, :show, :destroy, :edit, :archive]
  before_filter :require_login, :only => [:index, :create, :update, :show, :sent_messages, :new, :destroy, :emptytrash, :edit, :archive]
  
  # GET /user_messages
  # GET /user_messages.xml
  def index
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

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_messages }
    end
  end

  def contact_message
    @user_message = UserMessage.new()
    
    respond_to do |format|
      format.html # contact_message.html.erb
    end
  end

  def send_contact_message

    email = params[:email]
    if email.match(EMAIL_REGEX).nil?
      flash[:notice] = l(:text_message_sent_error_fields)
    else
      @user_message = UserMessage.new()
      contact = User.find(1)
      @user_message.receiver_id = contact.id
      @user_message.author = contact.id
      @user_message.user_id = contact.id
      flash[:notice] = l(:text_message_sent_done)
      @user_message.body = params[:user_message]["body"]
      @user_message.subject = "from #{email} #{params[:user_message]["subject"]}"
      @user_message.state = 1
      @user_message.directory = UserMessage.received_directory
      @user_message.save!
    end
    respond_to do |format|
      format.html { redirect_to(request.referer) }
    end
  end
  
  # GET /user_messages/1
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
    @user_message_reply_mail = params[:reply]
    @user_message_reply = ""
    if !params[:id].nil?
      user = User.find(params[:id])
      if !user.nil?
        @user_message_reply_id = user.id
        @user_message_reply = " log('#{user.firstname} #{user.lastname}');"
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
    p params[:user_message]["receiver"]
    if (params[:user_message]["receiver"].empty? || params[:user_message]["subject"].empty? || params[:user_message]["body"].empty?) 
      noerror = false;
      notice = l(:error_empty_message)
      @user_message_reply = notice
    else 
      unless params[:user_message]["receiver"].nil?
        @receiver_arr = params[:user_message]["receiver"].split(",")
        @receiver_arr.each do |receiver_id|
          recv = User.find_by_id(receiver_id)
          if recv.nil?
            @user_massage = UserMessage.new()
            flash[:notice] = l(:error_receiver_unknown)
            respond_to do |format|
              format.html { redirect_to(:action => 'new', :notice => 'Receiver not known') }
              format.xml  { render :xml => @user_message.errors, :status => :unprocessable_entity }
            end
            return 
          end
          @user_message = UserMessage.new()
          @user_message.body = params[:user_message]["body"]
          @user_message.subject = params[:user_message]["subject"]
          @user_message.user = User.current
          @user_message.author = User.current
          @user_message.receiver_id = recv.id
          @user_message.state = 3
          @user_message.directory = UserMessage.sent_directory

          @user_message_clone = @user_message.clone
          @user_message_clone.state = 1
          @user_message_clone.author = recv.id
          @user_message_clone.directory = UserMessage.received_directory
          noerror &= @user_message.save
          noerror &= @user_message_clone.save
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

  # DELETE /user_messages/1
  # DELETE /user_messages/1.xml
  def destroy
    @user_message = UserMessage.find(params[:id])
    if !params[:directory].nil? && params[:directory] == UserMessage.trash_directory
      @user_message.destroy
    else
      @user_message.state = 2
      @user_message.directory = UserMessage.trash_directory
      @user_message.save
    end

    respond_to do |format|
      format.html { redirect_to(request.referer, :notice => l(:text_message_delete_done)) }
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
    #@user_message.destroy

    respond_to do |format|
      format.html { redirect_to(request.referer, :notice => l(:text_message_archive_done)) }
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

  private

  def is_author?
    @user_message = UserMessage.find(params[:id])
    if !(@user_message.read_attribute("author").to_i == User.current.id.to_i)
      render_403
      return false 
    end
    return true
  end

    # State:    0 read message
    #           1 new message
    #           2 deleted message
    #           3 sent message (for getting Sent-Message)
    #           4 answered message
end
