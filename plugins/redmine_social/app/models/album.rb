class Album < ActiveRecord::Base
  unloadable
  acts_as_watchable
  has_many :photos, :dependent => :destroy
  belongs_to :user
  belongs_to :container, polymorphic: true
  validates_presence_of :user_id
  acts_as_event :title => Proc.new {|o| "#{o.title}"},
                :url => Proc.new {|o| {:controller => 'albums', :action => 'show', :id => o.id}}
  acts_as_activity_provider :find_options => {:include => [:user]},
                            :author_key => :user_id, :type => "albums"

  validates_presence_of :title  
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on DESC"
  attr_accessible :title, :description

  def owner
    self.user
  end

end
