class Photo < ActiveRecord::Base
  unloadable
  belongs_to :album
  acts_as_watchable

  validates_attachment_presence :photo
  validates_attachment_content_type :photo, :content_type => 
                            Setting.plugin_redmine_social['photo_content_type'].class == Array ? Setting.plugin_redmine_social['photo_content_type'] : 
                            Setting.plugin_redmine_social['photo_content_type'].to_s.split(" ")
  validates_attachment_size :photo, :less_than => Setting.plugin_redmine_social['photo_max_size'].to_i.megabytes

   has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  after_update :reprocess_photo, :if => :cropping?
  
  acts_as_taggable

  acts_as_activity_provider :find_options => {:include => [:user]},
                            :author_key => :user_id
  
  validates_presence_of :user
  
  belongs_to :user
  has_one :user_as_avatar, :class_name => "User", :foreign_key => "avatar_id", :inverse_of => :avatar
  
  #Named scopes
  scope :recent, :order => "photos.created_at DESC"
  scope :new_this_week, :order => "photos.created_at DESC", :conditions => ["photos.created_at > ?", 7.days.ago.iso8601]
  attr_accessible :name, :description, :photo, :crop_x, :crop_y, :crop_w, :crop_h, :user_id

  def self.settings_to_symbolize_keys(hash = Setting.plugin_redmine_social['photo_paperclip_options'].to_hash)
      n = hash.dup
      hash.each do |k,v| 
        n[k] = (self.settings_to_symbolize_keys(v)) if v.class == Hash 
        n[k] = (self.settings_to_symbolize_keys(v.to_hash)) if v.class == HashWithIndifferentAccess
        n[k] = v.split(" ").map{|m| m.to_sym if m.class == String } if k.to_s == "processors" && v.class == String
      end

      n = n.symbolize_keys
      return n
  end

  has_attached_file :photo, settings_to_symbolize_keys

  def display_name
    (self.name && self.name.length>0) ? self.name : "#{:created_at.l.downcase}: #{I18n.l(self.created_at, :format => :published_date)}"
  end

  def description_for_rss
    "<a href='#{self.link_for_rss}' title='#{self.name}'><img src='#{self.photo.url(:large)}' alt='#{self.name}' /><br />#{self.description}</a>"
  end

  def owner
    self.user
  end

  def previous_photo
    self.user.photos.where('created_at < ?', created_at).first
  end
  def next_photo
    self.user.photos.where('created_at > ?', created_at).last
  end

  def previous_in_album
    return nil unless self.album
    self.user.photos.where('created_at < ? and album_id = ?', created_at, self.album.id).first
  end
  def next_in_album
    return nil unless self.album
    self.user.photos.where('created_at > ? and album_id = ?', created_at, self.album_id).last
  end

  def self.file_exists?(photo_obj,style = :original)
    return File.exists?(photo_obj.photo.path(style))
  end

  def self.find_recent(options = {:limit => 3})
    self.new_this_week.find(:all, :limit => options[:limit])
  end
  
  def self.find_related_to(photo, options = {})
    options.reverse_merge!({:limit => 8, 
        :order => 'created_at DESC', 
        :conditions => ['photos.id != ?', photo.id]
    })
    limit(options[:limit]).order(options[:order]).where(options[:conditions]).tagged_with(photo.tags.collect{|t| t.name }, :any => true)
  end

  def cropping?
    !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
  end

  def photo_geometry(style = :original)
    @geometry ||= {}
    if File.exist?(photo.path(style))
      @geometry[style] ||= Paperclip::Geometry.from_file(photo.path(style))
    end
  end

  private

  def reprocess_photo
    photo.reprocess!
  end

end
