class ContactController < ApplicationController

  def index
    @contact_message = ContactMessage::new
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_messages }
    end
  end

  def send_message
    @contact_message = ContactMessage.new(params[:contact_message])
    if @contact_message.valid?
      Mailer.contact_message(@contact_message).deliver
      flash[:notice] = l(:text_message_sent_done)
      redirect_to url_for(:controller => 'welcome', :action => 'index')
    else
      flash[:notice] = l(:text_message_sent_error_fields)
      render :index
    end
  end

end
