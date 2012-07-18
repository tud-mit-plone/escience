class ChangeDatatypeForZipcode < ActiveRecord::Migration
  def self.up
    change_table :users do |t| 
      t.change :zipcode, :string, :limit => 5
    end
  end

  def self.down
    change_table :users do |t| 
      t.change :zipcode, :integer
    end
  end
end
