
# Use rake db:migrate_plugins to migrate installed plugins
class AddStoryTracker < ActiveRecord::Migration
  include Redmine::I18n

  def self.up
          t= Tracker.create!(:name => 'Story', :is_in_chlog => false, :is_in_roadmap => false, :position => 4)
          new       = IssueStatus.find_by_name(l(:default_issue_status_new))
          assigned  = IssueStatus.find_by_name(l(:default_issue_status_assigned))
          resolved  = IssueStatus.find_by_name(l(:default_issue_status_resolved))
          feedback  = IssueStatus.find_by_name(l(:default_issue_status_feedback))
          closed    = IssueStatus.find_by_name(l(:default_issue_status_closed))
          rejected  = IssueStatus.find_by_name(l(:default_issue_status_rejected))
          
          manager = Role.find_by_name(l(:default_role_manager))
          developper = Role.find_by_name(l(:default_role_developper))
          reporter = Role.find_by_name(l(:default_role_reporter))
          
          # Workflow
          IssueStatus.find(:all).each { |os|
            IssueStatus.find(:all).each { |ns|
              Workflow.create!(:tracker_id => t.id, :role_id => manager.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
            }        
          }      
          
          [new, assigned, resolved, feedback].each { |os|
            [assigned, resolved, feedback, closed].each { |ns|
              Workflow.create!(:tracker_id => t.id, :role_id => developper.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
            }        
          }      
          
          [new, assigned, resolved, feedback].each { |os|
            [closed].each { |ns|
              Workflow.create!(:tracker_id => t.id, :role_id => reporter.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
            }        
          }
          Workflow.create!(:tracker_id => t.id, :role_id => reporter.id, :old_status_id => resolved.id, :new_status_id => feedback.id)
  end

  def self.down
    Tracker.delete(:name => 'Story') #Hmmm wonder if this will cascade delete...
  end
end