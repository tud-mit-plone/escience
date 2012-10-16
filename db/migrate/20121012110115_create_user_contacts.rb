class CreateUserContacts < ActiveRecord::Migration
  def change
    create_table :user_contacts do |t|
      t.references :user
      t.references :contact_member

      t.timestamps
    end
    add_index :user_contacts, :user_id
    add_index :user_contacts, :contact_member_id
  end
end
