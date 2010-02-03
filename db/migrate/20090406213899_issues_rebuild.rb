# Need to assume Issues are valid in order to rebuild.
class Issue < ActiveRecord::Base
  def valid?
    true
  end
end

class IssuesRebuild < ActiveRecord::Migration
  def self.up
    Issue.rebuild!
  end

  def self.down
  end
end
