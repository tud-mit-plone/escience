class AlbumPolymorphyExtension < ActiveRecord::Migration
  def self.up
    add_column :albums, :container_id, :integer 
    add_column :albums, :container_type, :string    
  end

  def self.down
    remove_column :albums, :container_id
    remove_column :albums, :container_type
  end
end
