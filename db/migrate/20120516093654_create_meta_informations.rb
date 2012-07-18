class CreateMetaInformations < ActiveRecord::Migration
  def self.up
    create_table :meta_informations do |t|
      t.string :description
      t.string :meta_information
      t.string :uploader_information
      t.references :user
      t.references :attachment
      t.timestamps
    end
  end

  def self.down
    drop_table :meta_informations
  end
end
