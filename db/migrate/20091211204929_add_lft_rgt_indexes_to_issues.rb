class AddLftRgtIndexesToIssues < ActiveRecord::Migration
  def self.up
    add_index :issues, :lft
    add_index :issues, :rgt
  end

  def self.down
    remove_index :issues, :lft
    remove_index :issues, :rgt
  end
end
