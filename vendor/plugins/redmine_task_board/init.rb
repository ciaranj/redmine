require 'redmine'
RAILS_DEFAULT_LOGGER.info 'Starting Task Board plugin for RedMine'

require_dependency 'task_board_listener'

require_dependency 'scrum_alliance/redmine/issue_relation_extensions'
require_dependency 'scrum_alliance/redmine/issue_status_extensions'
require_dependency 'scrum_alliance/redmine/issue_extensions'
require_dependency 'scrum_alliance/redmine/project_extensions'

# Dependency loading hell. http://www.ruby-forum.com/topic/166578#new
require 'dispatcher'
Dispatcher.to_prepare do
  Project.class_eval { include ScrumAlliance::Redmine::ProjectExtensions }
  Issue.class_eval { include ScrumAlliance::Redmine::IssueExtensions }
  IssueRelation.class_eval { include ScrumAlliance::Redmine::IssueRelationExtensions }
  IssueStatus.class_eval { include ScrumAlliance::Redmine::IssueStatusExtensions }
end

Redmine::Plugin.register :redmine_task_board do
  name 'Redmine Task Board plugin'
  author 'Dan Hodos'
  description "Creates a drag 'n' drop task board of the items in the current version and their status"
  version '0.0.1'

  project_module :task_boards do  
    permission :view_task_boards, :task_boards => :show
    permission :update_task_boards, :task_boards => :update_status
  end
  
  menu :project_menu, :task_board, {:controller => 'task_boards', :action => 'show'}, :before => :burndown, :caption => 'Task Board'
end