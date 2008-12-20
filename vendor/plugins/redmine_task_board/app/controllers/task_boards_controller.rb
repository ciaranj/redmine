module StoryFinder
  def story
    story = relations_to.detect {|rel| rel.relation_type == 'composes' }
    story && story.issue_from
  end
end

class TaskBoardsController < ApplicationController
  unloadable
  menu_item :task_board
  
  before_filter :find_version_and_project, :authorize, :only => [:show]
  
  def show
    @statuses = IssueStatus.all(:order => "position asc")

    all_issues = @version.fixed_issues
    all_issues.each {|issue| issue.extend(StoryFinder)}
    all_issues = all_issues.group_by(&:story)
    
    @independent_tickets = all_issues.delete(nil).reject {|issue| all_issues.keys.include?(issue) }
    @independent_tickets = @independent_tickets.group_by(&:status)

    @stories_with_tasks = all_issues
    @stories_with_tasks.each do |story, tasks|
      @stories_with_tasks[story] = tasks.group_by(&:status)
    end
  end
  
  def update_issue_status
    @issue = Issue.find(params[:id])
    @issue.extend(StoryFinder)
    @issue.init_journal(User.current, "Automated status change from the Task Board")

    @status = IssueStatus.find(params[:status_id])
    @issue.update_attribute(:status_id, @status.id)
    
    render :update do |page|
      page.remove dom_id(@issue)
      element_id = @issue.story ? dom_id(@issue.story, @status.name.gsub(' ','').underscore + "_list") : "independent_#{@status.name.gsub(' ','').underscore}_list"
      page.insert_html :bottom, element_id, :partial => "issue", :object => @issue
    end
  end
  
private
  def find_version_and_project
    @project = Project.find(params[:id])
    @version = @project.current_version
    render_error("There is no current Sprint for this Project") and return unless @version
  end
end