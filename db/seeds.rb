Role.anonymous
Role.non_member
Role.member
Role.owner

default_tracker = Tracker.where(:name => "Aufgabe").first
default_tracker = Tracker.create(:name => "Aufgabe") if default_tracker.nil?

Project.create(:name => "eScience",
               :description => "Das Hauptprojekt der eScience Forschungsplattform, dem sich jeder Benutzer der Community anschliesst",
               :is_public => true,
               :identifier => "escience",
               :status => Project::STATUS_ACTIVE,
               :trackers => [default_tracker]) if Project.where(:identifier => "escience").first.nil?

status_open = IssueStatus.where(:name => "Offen").first
status_open = IssueStatus.create(:name => "Offen",
                                 :is_default => true,
                                 :is_closed => false) if status_open.nil?

status_closed = IssueStatus.where(:name => "Abgeschlossen").first
status_closed = IssueStatus.create(:name => "Abgeschlossen",
                                   :is_default => false,
                                   :is_closed => true) if status_closed.nil?

IssuePriority.create(:name => "Niedrig",
                     :is_default => false,
                     :active => true) if IssuePriority.where(:name => "Niedrig").first.nil?

IssuePriority.create(:name => "Normal",
                     :is_default => true,
                     :active => true) if IssuePriority.where(:name => "Normal").first.nil?

IssuePriority.create(:name => "Hoch",
                     :is_default => false,
                     :active => true) if IssuePriority.where(:name => "Hoch").first.nil?

[Role.member, Role.owner].each do |role|
  [{:old_status => status_open, :new_status => status_closed},
   {:old_status => status_closed, :new_status => status_open}].each do |record|
    record = record.merge({:role => role, :tracker => default_tracker})
    test_record = record.map{|key, value| ["#{key}_id", value]}.to_h
    WorkflowTransition.create(record) if WorkflowTransition.where(test_record).first.nil?
  end
end
