class ChangeSizeForDepartment < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `redmine`.`users` CHANGE COLUMN `department` `department` VARCHAR(256) NOT NULL DEFAULT '';"
  end

  def self.down
    execute "ALTER TABLE `redmine`.`users` CHANGE COLUMN `department` `department` VARCHAR(30) NOT NULL DEFAULT '';"
  end
end
