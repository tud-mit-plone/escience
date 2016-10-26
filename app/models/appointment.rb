class Appointment < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes
  include Redmine::Utils::DateCalculation

  belongs_to :user, :class_name => 'User', :foreign_key => 'author_id'

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  acts_as_watchable
  acts_as_attachable :after_add => :attachment_added, :after_remove => :attachment_removed
  acts_as_searchable :columns => ['subject', "#{table_name}.description", "#{Journal.table_name}.notes"],
                     :include => [:user, :visible_journals],
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.id"
  acts_as_event :title => Proc.new {|o| "#{o.subject}"},
                :url => Proc.new {|o| {:controller => 'appointments', :action => 'show', :id => o.id}}
  acts_as_activity_provider :find_options => {:include => [:author]},
                            :author_key => :author_id, :type => "appointments"
  delegate :notes, :notes=, :private_notes, :private_notes=, :to => :current_journal, :allow_nil => true
  validates_presence_of :subject, :user, :start_date
  validates_length_of :subject, :maximum => 255

  scope :visible, lambda {|*args| { :include => :user,
                          :conditions => "(#{table_name}.is_private = 0
                                                    OR #{table_name}.author_id = #{User.current.id}
                                                    OR #{User.current.id} IN (
                                                         SELECT DISTINCT user_id FROM #{Watcher.table_name},#{table_name}
                                                         WHERE watchable_type = \"Appointment\"
                                                         AND watchable_id = #{table_name}.id))" } }

  scope :own, lambda {|*args| { :conditions => "#{table_name}.author_id = #{User.current.id}" } }

  scope :non_private, lambda {|*args| { :conditions => "#{table_name}.is_private = 0" } }

  scope :watched, lambda {|*args| { :include => :user,
                                    :conditions => "#{User.current.id} IN (
                                                         SELECT DISTINCT user_id FROM #{Watcher.table_name},#{table_name}
                                                         WHERE watchable_type = \"Appointment\"
                                                         AND watchable_id = #{table_name}.id)" } }




  # Cycle values
  CYCLE_DAYLY   = 1
  CYCLE_WEEKLY  = 2
  CYCLE_MONTHLY = 3
  CYCLE_YEARLY  = 4

  def initialize(attributes=nil, *args)
    super
    if new_record?
      # set default values for new records only
      self.watcher_user_ids = []
    end
    self.cycle  ||= 0
  end

  def css_classes
    return @css_classes unless @css_classes.nil?
    @css_classes = 'appointment'
  end

  def project
    nil
  end
  def tracker
    nil
  end

  def to_s
    "#{subject}"
  end

  def self.getAllEventsWithResolvedCycles(scope, startdt=Date.today,enddt=Date.today)
    candidates = scope.where("(DATE(#{table_name}.start_date) >= ? AND DATE(#{table_name}.due_date) <= ?)
                              OR (DATE(#{table_name}.start_date) >= ? AND DATE(#{table_name}.start_date) <= ? AND #{table_name}.due_date IS NULL)",
                             startdt, enddt, startdt, enddt)
    events = []
    candidates.each do |event|
      if event[:cycle] == 0
        events += [event]
      else
        offset = case event[:cycle]
                   when CYCLE_DAYLY then 1.day
                   when CYCLE_WEEKLY then 1.week
                   when CYCLE_MONTHLY then 1.month
                   when CYCLE_YEARLY then 1.year
                 end
        end_date = event.due_date || event.start_date
        effective_start_date = event.start_date
        effective_end_date =
        effective_end_date = Time.new(effective_start_date.year,
                                  effective_start_date.month,
                                  effective_start_date.day,
                                  (end_date).hour,
                                  (end_date).min,
                                  (end_date).sec,
                                  effective_start_date.utc_offset)
        effective_end_date = effective_start_date if effective_end_date < effective_start_date
        while effective_end_date.to_date <= end_date.to_date
          if effective_start_date.to_date >= startdt && effective_end_date <= enddt
            effective_event = event.clone
            effective_event.start_date = effective_start_date
            effective_event.due_date = effective_end_date
            events += [effective_event]
          end
          effective_start_date += offset
          effective_end_date += offset
        end
      end
    end
    events
  end

  def visible?(user=nil)
    user ||= User.current
    if user.logged?
      !self.is_private? || self.user == user || self.watched_by?(user)
    else
      !self.is_private?
    end
  end

  def clone
    attributes = self.attributes.dup
    copy = Appointment.new(attributes)
    copy.id = self.id
    return copy
  end

  def destroy
    super
  rescue ActiveRecord::RecordNotFound
    # Stale or already deleted
    begin
      reload
    rescue ActiveRecord::RecordNotFound
      # The issue was actually already deleted
      @destroyed = true
      return freeze
    end
    # The issue was stale, retry to destroy
    super
  end

  safe_attributes 'subject',
    'description',
    'start_date',
    'due_date',
    'cycle',
    'doodle_participants',
    'is_private',
    'notes',
    'category_id',
    'watcher_user_ids',
    :if => lambda {|appointment, user| appointment.new_record? || user.allowed_to?(:edit_appointment, appointment) }

  safe_attributes 'notes',
    :if => lambda {|appointment, user| user.allowed_to?(:add_issue_notes, appointment)}

  safe_attributes 'watcher_user_ids',
    :if => lambda {|appointment, user| appointment.new_record? && user.allowed_to?(:add_appointment_watchers, appointment)}

  def safe_attributes=(attrs, user=User.current)
    return unless attrs.is_a?(Hash)

    attrs = attrs.dup
    attrs = delete_unsafe_attributes(attrs, user)
    return if attrs.empty?

    # mass-assignment security bypass
    assign_attributes attrs, :without_protection => true
  end

end
