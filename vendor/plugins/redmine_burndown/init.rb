require 'redmine'
require 'gchart' 
require_dependency 'burndown_listener'

Redmine::Plugin.register :burndown do
  name 'Burndown'
  author 'Dan Hodos'
  description 'Generates a simple Burndown chart for using Redmine in Scrum environments'
  version '0.0.1'

  project_module :burndowns do  
    permission :show_burndown, :burndowns => :show, :public => true
  end

  menu :project_menu, :burndown, { :controller => 'burndowns', :action => 'show' }, :before  => :activity
end