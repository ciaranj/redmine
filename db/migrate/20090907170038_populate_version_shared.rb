class PopulateVersionShared < ActiveRecord::Migration
  def self.up
    Version.update_all('shared = "none"', ['shared IS NULL OR shared = ?',''])
  end

  def self.down
    # No-op
  end
end
