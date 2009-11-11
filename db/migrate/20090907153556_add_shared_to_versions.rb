class AddSharedToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :shared, :string, :default => 'none', :null => false
    add_index :versions, :shared
  end

  def self.down
    remove_column :versions, :shared
  end
end
