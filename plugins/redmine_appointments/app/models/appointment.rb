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
                          :conditions => "(#{table_name}.is_private = #{connection.quoted_false} 
                                                    OR #{table_name}.author_id = #{User.current.id} 
                                                    OR #{User.current.id} IN (
                                                         SELECT DISTINCT user_id FROM #{Watcher.table_name},#{table_name} 
                                                         WHERE watchable_type = \"Appointment\"
                                                         AND watchable_id = #{table_name}.id))" } }

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
  
  def self.getAllEventsWithCycle(startdt=Date.today,enddt=Date.today)
    visible_appointments = self.find(:all).select{|a| a.visible? || a.author == User.current}
    visible_appointments = visible_appointments - self.watched_by(User.current)

    if startdt == enddt
      appointments = self.find(:all, :conditions => ["(id in (?) AND DATE(start_date) >= ? 
                    AND DATE(due_date) <= ?) OR (DATE(start_date) >= ? 
                    AND DATE(start_date) <= ? 
                    AND due_date IS NULL) OR (DATE(start_date) = ? 
                    AND cycle > 0)", visible_appointments.map{|i| i.id }, startdt, enddt, startdt, enddt, startdt ])
    else
      appointments = self.find(:all, :conditions => ["(id in (?) AND DATE(start_date) >= ? 
                    AND DATE(due_date) <= ?) OR (DATE(start_date) >= ? 
                    AND DATE(start_date) <= ? 
                    AND due_date IS NULL)",visible_appointments.map{|i| i.id }, startdt, enddt, startdt, enddt ])
    end    
    events = appointments
    appointments = self.find(:all, :conditions => ["id in (?) AND cycle > 0", visible_appointments.map{|i| i.id }])
    appointments.each do |appointment|
      begin
        if appointment[:cycle] == CYCLE_WEEKLY
          repeated_day = appointment[:start_date]+7.day
          while (repeated_day < enddt && repeated_day <= (appointment[:due_date] || enddt)) || (enddt == startdt && repeated_day <= (appointment[:due_date] || enddt))
            event = appointment.clone
            event[:start_date] = repeated_day
            events += [event] if (enddt == startdt && repeated_day == startdt) || enddt != startdt
            repeated_day += 7.day
          end
        elsif appointment[:cycle] == CYCLE_MONTHLY
          repeated_day = appointment[:start_date]+1.month
          while (repeated_day < enddt && repeated_day <= (appointment[:due_date] || enddt)) || (enddt == startdt && repeated_day <= (appointment[:due_date] || enddt))
            event = appointment.clone
            event[:start_date] = repeated_day 
            events += [event] if (enddt == startdt && repeated_day == startdt) || enddt != startdt
            repeated_day = repeated_day+1.month
          end
        end
      rescue => e 
        e.backtrace.map{ |x|   
          x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
          p [$1,$2,$4] 
        }
      end
    end
    return events
  end
  
  def self.getListOfDaysBetween(startdt=Date.today,enddt=Date.today)
    appointments = self.find(:all, :conditions => ["cycle = 0"])
    listOfDaysBetween = {}
    appointments.each do |appointment|
      if appointment[:start_date] >= startdt && appointment[:start_date] < enddt && appointment[:start_date] != appointment[:due_date] && !appointment[:due_date].nil?
        currentDate = appointment[:start_date].to_date.to_time + 1.day
        while currentDate < appointment[:due_date] && currentDate <= enddt
          if listOfDaysBetween[currentDate.to_date.to_s].nil?
            listOfDaysBetween[currentDate.to_date.to_s] = [appointment]
          else listOfDaysBetween[currentDate.to_date.to_s].is_a?(Array)
            listOfDaysBetween[currentDate.to_date.to_s] = [listOfDaysBetween[currentDate.to_date.to_s],appointment]
          end
          currentDate += 1.day
        end
      end
    end
    return listOfDaysBetween
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
