module RedmineSocialExtends
  module MailerExtension
      module ClassMethods
      end
      
      module InstanceMethods
        def comment_added(comment)
          # comment_to =  
          # model = m_name.constantize.find(params[id.to_sym])
          # model_name = m_name.downcase.singularize
          # news = comment.commented
          # redmine_headers ""
          # @author = comment.author
          # message_id comment
          # @news = news
          # @comment = comment
          # @news_url = url_for(:controller => 'news', :action => 'show', :id => news)
          # mail :to => news.recipients,
          #  :cc => news.watcher_recipients,
          #  :subject => "Re: [#{news.project.name}] #{l(:label_news)}: #{news.title}"
        end
        
        def user_message_sent(user_message)
          redmine_headers l(:label_user_message).gsub(/\W+/,"") => user_message.subject,
                                       l(:label_user_message).gsub(/\W+/,"") => user_message.id
          message_id user_message
          @user_message = user_message
          @author = user_message.user
          @user_message_url = url_for(:controller => 'user_messages', :action => 'show', :id => user_message.id)
          mail(:to => user_message.recipients_mail, 
                  :subject => "[#{l(:label_user_message)}] #{l(:label_from)} #{user_message.user}: #{user_message.subject}") do |format| 
            format.html { render 'mailer/user_message_sent'}
            format.text { render 'mailer/user_message_sent'}
          end
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          def self.message_id_for(object)
            # id + timestamp should reduce the odds of a collision
            # as far as we don't send multiple emails for the same object
            if object.respond_to?(:created_on)
              timestamp = object.send(:created_on) 
            elsif object.respond_to?(:updated_on)
              timestamp = object.send(:updated_on)
            elsif object.respond_to?(:created_at)
              timestamp = object.send(:created_at)            
            elsif object.respond_to?(:updated_at)
              timestamp = object.send(:updated_at)  
            end
            hash = "redmine.#{object.class.name.demodulize.underscore}-#{object.id}.#{timestamp.strftime("%Y%m%d%H%M%S")}"
            host = Setting.mail_from.to_s.gsub(%r{^.*@}, '')
            host = "#{::Socket.gethostname}.redmine" if host.empty?
            "#{hash}@#{host}"
          end
        end
      end
    end
  end