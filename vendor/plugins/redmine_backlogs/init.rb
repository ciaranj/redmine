require 'redmine'

require_dependency 'backlog_listener'
require_dependency 'project'

Redmine::Plugin.register :redmine_backlog do
  name 'Redmine Backlogs plugin'
  author 'Dan Hodos'
  description "Adds 'Sprint Backlog' and 'Product Backlog' tabs"
  version '0.0.1'
  
  project_module :sprint_backlogs do  
    permission :sprint_backlog, {:backlogs => [:sprint]}, :public => true
  end
  
  Redmine::MenuManager.map :project_menu do |menu|
    menu.delete :overview
    menu.delete :roadmap
    menu.delete :issues
    menu.delete :new_issue
  end
  
  permission :product_backlog, {:backlogs => [:product]}, :public => true
  
  menu :application_menu, :product_backlog, {:controller => 'backlogs', :action => 'product'}, :caption => 'Product Backlog'
  menu :project_menu, :product_backlog, {:controller => 'backlogs', :action => 'product'}, :caption => 'Product Backlog', :first => true
  
  menu :project_menu, :sprint_backlog, {:controller => 'backlogs', :action => 'sprint'}, :after => :product_backlog, :caption => 'Sprint Backlog'
end