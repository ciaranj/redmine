class BacklogsController < ApplicationController
  unloadable
  
  helper :issues
  
  menu_item :product_backlog, :only => [:product]
  menu_item :sprint_backlog, :only => [:sprint]
  
  before_filter :find_project, :authorize

  def sprint
    @current_sprint = @project.current_version
    render_error("There is no current Sprint for this Project") and return unless @current_sprint
    
    @task_tracker = @project.trackers.detect {|tracker| 'task' == tracker.name.downcase }
    
    @backlog_title = "Sprint Backlog Tickets"    
    @backlog_url = url_for(:controller => 'issues', :project_id => @project, :set_filter => 1, 
      :fields => [:status_id, :fixed_version_id], 
      :operators => {:status_id => '*', :fixed_version_id => '='}, 
      :values => {:status_id => [1], :fixed_version_id => [@current_sprint.id]},
      :column_names => [:tracker, story_points_name, :priority, :subject, :assigned_to, :status, :estimated_hours, :done_ratio].compact)
  end
  
  def product
    @parent_project = @project.parent || @project
    @story_tracker = @parent_project.trackers.detect {|tracker| 'story' == tracker.name.downcase }
    
    @backlog_title = "Product Backlog Tickets"
    @backlog_url = url_for(:controller => 'issues', :set_filter => 1, :project_id => @parent_project,
      :fields => [:status_id, :tracker_id, :fixed_version_id], 
      :operators => {:status_id => 'o', :tracker_id => '!', :fixed_version_id => '!*'}, 
      :values => {:status_id => 'o', :fixed_version_id => [1], :tracker_id => [3]},
      :column_names => [:tracker, :priority, :subject, :updated_on, story_points_name].compact, 
      :sort_key => "enumerations.position", :sort_order => 'desc')
  end

private

  def story_points_name
    story_points_field = IssueCustomField.find_by_name("Story Points")
    story_points_field && "cf_#{story_points_field.id}" # janky, but loading QueryCustomFieldColumn is a pain.
  end

  def find_project
    @project = if params[:id]
      Project.find(params[:id])
    else
      project = Project.first
      project.parent || project
    end
  end
end