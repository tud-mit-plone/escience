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

        def get_history
          return [self] if self.parent.nil? 
          parents = [self.id]
          parent = self.parent

          begin 
            break if parents.include?(parent) || parent.parent.nil? || parent.id == parent.parent.id
            parents << parent.id
            parent = parent.parent 
          end while !parent.nil?
          parents = UserMessage.where(:id  => parents).where("author = ?", User.current)

          return parents 
        end

        def generate_sent_receiver_copy(receiver_id = self.receiver_id, receiver_list = nil)
          recv_id = receiver_list.nil? ? receiver_id : nil
          answ = UserMessage.new({ :body => self.body,
                                                                 :subject => self.subject,
                                                                 :user_id => self.user.id,
                                                                 :author => receiver_id,
                                                                 :receiver_id => recv_id,
                                                                 :receiver_list => receiver_list,
                                                                 :state => 1,
                                                                 :directory => UserMessage.received_directory, 
                                                                 :parent => self})
          answ.save 
          return answ
        end
        def recipients_mail
          return [User.where(:id => self.receiver_id) || self.receiver_list].flatten.collect(&:mail)
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do

          serialize :receiver_list, Array

          has_and_belongs_to_many :group_invitations,
                        :join_table => :invitation_user_messages,
                        :foreign_key => :user_message_id,
                        :association_foreign_key => :group_invitation_id
          #it's expensive to search for all children, but atm it's not necessary
          belongs_to :parent, :class_name =>'UserMessage', :foreign_key => :user_message_parent_id

          after_save :send_mails

          def receiver_list
            recv = read_attribute(:receiver_list)
            return User.where( :id => recv) if !(recv.nil? || recv.length == 0)
          end
        end
      end
    end
        module UserMessagesControllerExtension
      module ClassMethods

      end
      module InstanceMethods
        private 
          def get_reply_message
            @user_message_reply_mail = UserMessage.where(:id => params[:reply], :author => User.current.id).first
          end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
            include ApplicationHelper

            before_filter :get_reply_message,  :only => [:new, :create, :show] 

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

            def history_messages
              history = UserMessage.where(:id => params[:id]).where(:author => User.current)
              respond_to do |format|
                format.json render :json => history
              end
            end
        end
      end
    end
  end