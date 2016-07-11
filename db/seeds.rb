Role.anonymous
Role.non_member
Role.member
Role.owner

default_tracker = Tracker.create :name => "Aufgabe"

Project.create :name => "eScience",
               :description => "Das Hauptprojekt der eScience Forschungsplattform, dem sich jeder Benutzer der Community anschliesst",
               :is_public => true,
               :identifier => "escience",
               :status => Project::STATUS_ACTIVE,
               :trackers => [default_tracker]

IssueStatus.create :name => "Offen",
                   :is_default => true,
                   :is_closed => false

IssueStatus.create :name => "Abgeschlossen",
                   :is_default => false,
                   :is_closed => true

IssuePriority.create :name => "Niedrig",
                     :is_default => false,
                     :active => true

IssuePriority.create :name => "Normal",
                     :is_default => true,
                     :active => true

IssuePriority.create :name => "Hoch",
                     :is_default => false,
                     :active => true
