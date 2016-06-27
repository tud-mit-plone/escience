class RemoveBuiltinRoles < ActiveRecord::Migration
  def up
    Role.delete_all 'builtin <> 0'
  end

  def down
  end
end
