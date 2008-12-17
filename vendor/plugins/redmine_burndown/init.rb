require 'redmine'
require 'gchart' 
require_dependency 'burndown_listener'

Redmine::Plugin.register :burndown do
  name 'Burndown'
  author 'Dan Hodos'
  description 'Generates a simple Burndown chart for using Redmine in Scrum environments'
  version '0.0.1'

  permission :show_burndown, :burndowns => :show, :public => true
end