class TaskBoardsController < ApplicationController
  unloadable
  menu_item :roadmap
  
  before_filter :find_version_and_project, :authorize, :only => [:show]
  
  def show
    @statuses = IssueStatus.all(:order => "position asc")
    @issues_by_status = @version.fixed_issues.group_by(&:status)
  end
  
  def update_issue_status
    @issue = Issue.find(params[:id])
    @status = IssueStatus.find(params[:status_id])
    
    @issue.init_journal(User.current, "Automated status change from the Task Board")
    @issue.update_attribute(:status_id, @status.id)
    
    render :update do |page|
      page.remove dom_id(@issue)
      page.insert_html :bottom, dom_id(@status, 'list'), :partial => "issue", :object => @issue
    end
  end
  
private
  def find_version_and_project
    @version = Version.find(params[:id])
    @project = @version.project
  end
end