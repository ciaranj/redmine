require 'redmine'
RAILS_DEFAULT_LOGGER.info 'Starting Task Board plugin for RedMine'

require_dependency 'task_board_listener'

Redmine::Plugin.register :redmine_task_board do
  name 'Redmine Task Board plugin'
  author 'Dan Hodos'
  description "Creates a drag 'n' drop task board of the items in the current version and their status"
  version '0.0.1'

  project_module :task_boards do  
    permission :view_task_boards, :task_boards => :show
    permission :update_task_boards, :task_boards => :update_status
  end
end