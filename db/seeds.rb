Role.anonymous
Role.non_member
Role.member
Role.owner

Project.create :name => "eScience",
               :description => "Das Hauptprojekt der eScience Forschungsplattform, dem sich jeder Benutzer der Community anschliesst",
               :is_public => true,
               :identifier => "escience",
               :status => Project::STATUS_ACTIVE
