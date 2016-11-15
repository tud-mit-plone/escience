class UserMessage < ActiveRecord::Base
  belongs_to :user
  belongs_to :receiver, :class_name => "User", :foreign_key => "receiver_id"
  has_and_belongs_to_many :group_invitations,
                :join_table => :invitation_user_messages,
                :foreign_key => :user_message_id,
                :association_foreign_key => :group_invitation_id
  #it's expensive to search for all children, but atm it's not necessary
  belongs_to :parent, :class_name =>'UserMessage', :foreign_key => :user_message_parent_id
  serialize :receiver_list, Array
  after_save :send_mails


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

  def send_mails
    Mailer.user_message_sent(self).deliver
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

  def receiver_list
    recv = read_attribute(:receiver_list)
    return User.where( :id => recv) if !(recv.nil? || recv.length == 0)
  end

end
