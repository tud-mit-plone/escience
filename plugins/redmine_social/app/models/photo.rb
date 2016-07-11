class Photo < ActiveRecord::Base
  unloadable
  acts_as_watchable

  validates_attachment_presence :photo
  validates_attachment_content_type :photo, :content_type =>
                            Setting.plugin_redmine_social['photo_content_type'].class == Array ? Setting.plugin_redmine_social['photo_content_type'] :
                            JSON.parse(Setting.plugin_redmine_social['photo_content_type'])
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

  #p "#{JSON.parse(Setting.plugin_redmine_social['photo_paperclip_options'].to_s.gsub("=>",":"))}"
  #p "#{settings_to_symbolize_keys}"

  has_attached_file :photo, settings_to_symbolize_keys

  def display_name
    (self.name && self.name.length>0) ? self.name : "#{l(:created_at).downcase}: #{I18n.l(self.created_at, :format => :published_date)}"
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

  def maincolor
    if @maincolor.nil?

      img =  Magick::Image.read(self.photo.path).first
      total = 0
      avg   = { :r => 0.0, :g => 0.0, :b => 0.0 }
      # img.quantize.color_histogram.each { |c, n|
      #     avg[:r] += n * c.red
      #     avg[:g] += n * c.green
      #     avg[:b] += n * c.blue
      #     total   += n
      # }
      # img.quantize(1,Magick::RGBColorspace).color_histogram.each { |c, n|
      #     avg[:r] += n * c.red
      #     avg[:g] += n * c.green
      #     avg[:b] += n * c.blue
      #     total   += n
      # }
      pix = img.scale(1, 1)
      @maincolor = pix.pixel_color(0,0)
    end
    return pix.to_color(@maincolor)

    [:r, :g, :b].each { |comp| avg[comp] = ((avg[comp] / (Magick::QuantumRange)).to_i & 255)}
    #[:r, :g, :b].each { |comp| avg[comp] = (avg[comp].to_i & 255).to_s.to_i(16) }
    str = '#'
    avg.values.each do |col|
      str += sprintf("%02X",col)
    end
    return str
  end

  def maincolor_rgb
    if @maincolor.nil?
      self.maincolor
    end
    return [((@maincolor.red * 255).to_f / Magick::QuantumRange).to_i,((@maincolor.green * 255).to_f / Magick::QuantumRange).to_i,((@maincolor.blue * 255).to_f / Magick::QuantumRange).to_i]
  end

  private

  def reprocess_photo
    photo.reprocess!
  end

end
