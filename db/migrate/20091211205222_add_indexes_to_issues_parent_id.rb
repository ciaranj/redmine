class AddIndexesToIssuesParentId < ActiveRecord::Migration
  def self.up
    add_index :issues, :parent_id
  end

  def self.down
    remove_index :issues, :parent_id
  end
end
