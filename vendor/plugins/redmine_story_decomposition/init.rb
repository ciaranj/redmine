require 'redmine'

Redmine::Plugin.register :redmine_story_decomposition do
  name 'Redmine Story Decomposition plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  
  permission :decompose_story, { :decompositions => [:index, :new, :create] }, :public => true
end