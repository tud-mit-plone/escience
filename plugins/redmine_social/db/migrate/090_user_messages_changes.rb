class UserMessagesChanges < ActiveRecord::Migration
  def self.up
    create_table :invitation_user_messages,{:id => false} do |t|
      t.references :user_message, :null => false
      t.references :group_invitation, :null => false
    end
    
    add_index :invitation_user_messages, [:user_message_id, :group_invitation_id], :name => "index_user_messages_on_groupinvitations", :unique => true

    create_table :group_invitations do |t|
      t.references :friendship_status, :null => false 
      t.string :group_type, :limit => 30, :default => "", :null => false 
      t.integer :group_id, :null => false 
      t.timestamps
    end

    add_column :user_messages, :message_type, :string, :limit => 30, :default => "", :null => false
    add_column :user_messages, :message_id, :integer    
    add_column :user_messages, :user_message_parent_id, :integer
  end

  def self.down
    remove_index :invitation_user_messages, :name => "index_user_messages_on_groupinvitations"
    remove_column :user_messages, :message_type 
    remove_column :user_messages, :message_id
    remove_column :user_messages,:user_message_parent_id
    drop_table :group_invitations
    drop_table :invitation_user_messages
  end
end
