class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :appointments do |t|
      t.integer :id
      t.integer :author_id
      t.string :subject
      t.text :description
      t.datetime :start_date
      t.datetime :due_date
      t.integer :cycle
      t.integer :signal
      t.integer :doodle_participants
      t.integer :category_id
      t.integer :parent_id
      t.datetime :created_on
      t.datetime :updated_on
      t.integer :is_private
    end
  end
end
