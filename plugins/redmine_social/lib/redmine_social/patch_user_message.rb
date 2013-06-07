module RedmineSocialExtends
    module UserMessagesExtension
      module ClassMethods
      end
      
      module InstanceMethods
        def send_mails
          send = false 
          if self.author.class == User 
            send = self.user == self.author
          else 
            send = self.user_id == self.author
          end

          if send
            Mailer.user_message_sent(self).deliver
          end
        end

        def generate_sent_receiver_copy(receiver_id = self.receiver_id)
          return UserMessage.new({ :body => self.body,
                                                                 :subject => self.subject,
                                                                 :user_id => self.user.id,
                                                                 :author => receiver_id,
                                                                 :receiver_id => receiver_id,
                                                                 :state => 1,
                                                                 :directory => UserMessage.received_directory, 
                                                                 :parent => self})
        end
        def recipients_mail
          return [self.receiver_id || self.receiver_list].flatten.map{|m| User.find(m)}.collect(&:mail)
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          has_and_belongs_to_many :group_invitations,
                        :join_table => :invitation_user_messages,
                        :foreign_key => :user_message_id,
                        :association_foreign_key => :group_invitation_id
          #it's expensive to search for all children, but atm it's not necessary
          belongs_to :parent, :class_name =>'UserMessage', :foreign_key => :user_message_parent_id

          after_save :send_mails
        end
      end
    end
        module UserMessagesControllerExtension
      module ClassMethods

      end
      module InstanceMethods

      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
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
                    if @user_message.new_record?
                      @user_message = UserMessage.new()
                      @user_message.body = params[:user_message]["body"]
                      @user_message.subject = params[:user_message]["subject"]
                      @user_message.user = User.current
                      @user_message.author = User.current
                      @user_message.receiver_id = recv.id
                      @user_message.state = 3
                      @user_message.directory = UserMessage.sent_directory
                      noerror &= @user_message.save
                    else

                    end
                    @user_message.generate_sent_receiver_copy(recv.id)
                    sent_users << recv.id
                  end
                  
                  if sent_users > 1 
                    @user_massage.receiver_list = sent_users.join(",")
                    @user_message.receiver_id = nil
                    @user_massage.update
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
        end
      end
    end
  end