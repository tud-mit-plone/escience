class CreateOwnerRole < ActiveRecord::Migration
  def up
    Role.owner
  end

  def down
    Role.delete_all(name: 'Owner')
  end
end
