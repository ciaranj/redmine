class TaskBoardsController < ApplicationController
  unloadable
  menu_item :task_board
  
  before_filter :find_version_and_project, :authorize, :only => [:show]
  
  def show
    @statuses = IssueStatus.all(:order => "position asc")
    
    @stories_with_tasks = @version.fixed_issues.group_by(&:story)
    if @stories_with_tasks[nil]
      @stories_with_tasks[nil] = @stories_with_tasks[nil].reject {|issue| @stories_with_tasks.keys.include?(issue) }
    end
    
    @stories_with_tasks.each do |story, tasks|
      @stories_with_tasks[story] = tasks.group_by(&:status)
    end
  end
  
  def update_issue_status
    @issue = Issue.find(params[:id])
    @issue.init_journal(User.current, "Automated status change from the Task Board")

    @status = IssueStatus.find(params[:status_id])
    @issue.update_attribute(:status_id, @status.id)
    
    render :update do |page|
      page.remove dom_id(@issue)
      page.insert_html :bottom, task_board_dom_id(@issue.story, @status, "list"), :partial => "issue", :object => @issue
    end
  end
  
private
  def find_version_and_project
    @project = Project.find(params[:id])
    @version = @project.current_version
    render_error("There is no current Sprint for this Project") and return unless @version
  end
end