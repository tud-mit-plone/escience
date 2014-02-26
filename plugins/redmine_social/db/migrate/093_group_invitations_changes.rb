class GroupInvitationsChanges< ActiveRecord::Migration
  def self.up
    add_column :group_invitations, :role_ids, :string, :default => "", :null => true
  end

  def self.down
    remove_column :group_invitations, :role_ids
  end
end