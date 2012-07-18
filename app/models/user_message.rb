class UserMessage < ActiveRecord::Base
    belongs_to :user
    belongs_to :receiver, :class_name => "User", :foreign_key => "receiver_id"

    # State:    0 read message
    #           1 new message
    #           2 deleted message
    #           3 sent message (for getting Sent-Message)
    #           4 answered message

    def self.get_number_of_messages
        #msgs = self.where("receiver_id = #{User.current.id}")
        msgs = self.find_by_sql("SELECT * FROM user_messages WHERE author = #{User.current.id} AND state = 1")
        #msgs = self.find_by_receiver_id(User.current.id)
        if msgs.class != Array && !msgs.nil?
          user_messages ||= []
          user_messages << msgs
        else
          user_messages = msgs
        end
        user_messages.nil? ? 0 : user_messages.length
    end

    def self.sent_directory
      return "sent"
    end

    def self.received_directory
      return "received"
    end

    def self.trash_directory
      return "trash"
    end

    def self.archive_directory
      return "archive"
    end

    def self.get_names_of_sender
        #msgs = self.where("receiver_id = #{User.current.id}")
        msgs = self.find_by_sql("SELECT author, id, created_at FROM user_messages WHERE receiver_id = #{User.current.id} AND state = 1 ORDER BY created_at DESC")
        #msgs = self.find_by_receiver_id(User.current.id)
        if msgs.class != Array && !msgs.nil?
          user_messages ||= []
          user_messages << msgs
        else
          user_messages = msgs
        end
        user_messages
    end


    def author_name
      begin
        author = User.find(self.read_attribute("author"))
        return "#{author.lastname}, #{author.firstname}"
      rescue ActiveRecord::RecordNotFound
        return self.read_attribute("author")
      end
    end

end
