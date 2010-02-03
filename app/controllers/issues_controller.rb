# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class IssuesController < ApplicationController
  menu_item :new_issue, :only => :new
  default_search_scope :issues
  
  before_filter :find_issue, :only => [:show, :edit, :reply]
  before_filter :find_issues, :only => [:bulk_edit, :move, :destroy]
  before_filter :find_project, :only => [:new, :update_form, :preview, :add_subissue, :auto_complete_for_issue_parent]
  before_filter :authorize, :except => [:index, :changes, :gantt, :calendar, :preview, :context_menu, :add_subissue]
  before_filter :find_optional_project, :only => [:index, :changes, :gantt, :calendar]
  before_filter :find_parent_issue, :only => [:add_subissue]
  before_filter :find_optional_parent_issue, :only => [:new, :update_form]

  accept_key_auth :index, :show, :changes

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  
  helper :journals
  helper :projects
  include ProjectsHelper   
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  include Redmine::Export::PDF
  include ActionView::Helpers::PrototypeHelper

  verify :method => :post,
         :only => :destroy,
         :render => { :nothing => true, :status => :method_not_allowed }
           
  def index
    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update({'id' => "#{Issue.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))
    
    if @query.valid?
      limit = per_page_option
      respond_to do |format|
        format.html { }
        format.atom { limit = Setting.feeds_limit.to_i }
        format.csv  { limit = Setting.issues_export_limit.to_i }
        format.pdf  { limit = Setting.issues_export_limit.to_i }
      end
      
      @issue_count = @query.issue_count
      @issue_pages = Paginator.new self, @issue_count, limit, params['page']
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause, 
                              :offset => @issue_pages.current.offset, 
                              :limit => limit)
      @issue_count_by_group = @query.issue_count_by_group
      
      respond_to do |format|
        format.html { render :template => 'issues/index.rhtml', :layout => !request.xhr? }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(issues_to_csv(@issues, @project), :type => 'text/csv; header=present', :filename => 'export.csv') }
        format.pdf  { send_data(issues_to_pdf(@issues, @project, @query), :type => 'application/pdf', :filename => 'export.pdf') }
      end
    else
      # Send html if the query is not valid
      render(:template => 'issues/index.rhtml', :layout => !request.xhr?)
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def changes
    retrieve_query
    sort_init 'id', 'desc'
    sort_update({'id' => "#{Issue.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))
    
    if @query.valid?
      @journals = @query.journals(:order => "#{Journal.table_name}.created_on DESC", 
                                  :limit => 25)
    end
    @title = (@project ? @project.name : Setting.app_title) + ": " + (@query.new_record? ? l(:label_changes_details) : @query.name)
    render :layout => false, :content_type => 'application/atom+xml'
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def show
    retrieve_query_for_subissues
    @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @changesets = @issue.changesets
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.all
    @time_entry = TimeEntry.new
    respond_to do |format|
      format.html { render :template => 'issues/show.rhtml' }
      format.atom { render :action => 'changes', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf  { send_data(issue_to_pdf(@issue), :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf") }
    end
  end

  # Add a new issue
  # The new issue will be created from an existing one if copy_from parameter is given
  def new
    @issue = Issue.new
    @issue.copy_from(params[:copy_from]) if params[:copy_from]
    @issue.project = @project
    # Tracker must be set before custom field values
    @issue.tracker ||= @project.trackers.find((params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first)
    if @issue.tracker.nil?
      render_error l(:error_no_tracker_in_project)
      return
    end
    if params[:issue].is_a?(Hash)
      @issue.attributes = params[:issue]
      @issue.watcher_user_ids = params[:issue]['watcher_user_ids'] if User.current.allowed_to?(:add_issue_watchers, @project)
    end
    @issue.author = User.current
    
    default_status = IssueStatus.default
    unless default_status
      render_error l(:error_no_default_issue_status)
      return
    end    
    @issue.status = default_status
    @allowed_statuses = ([default_status] + default_status.find_new_statuses_allowed_to(User.current.roles_for_project(@project), @issue.tracker)).uniq
    
    if request.get? || request.xhr?
      @issue.start_date ||= Date.today
    else
      requested_status = IssueStatus.find_by_id(params[:issue][:status_id])
      # Check that the user is allowed to apply the requested status
      @issue.status = (@allowed_statuses.include? requested_status) ? requested_status : default_status
      call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
      @issue.parent_id = params[:issue][:parent_id] if params[:issue]
      if @issue.save
        attach_files(@issue, params[:attachments])
        flash[:notice] = l(:notice_successful_create)
        call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
        redirect_to(params[:continue] ? { :action => 'new', :tracker_id => @issue.tracker } :
                                        { :action => 'show', :id => @issue })
        return
      end		
    end	
    @priorities = IssuePriority.all
    render :layout => !request.xhr?
  end
  
  # Attributes that can be updated on workflow transition (without :edit permission)
  # TODO: make it configurable (at least per role)
  UPDATABLE_ATTRS_ON_TRANSITION = %w(status_id assigned_to_id fixed_version_id done_ratio) unless const_defined?(:UPDATABLE_ATTRS_ON_TRANSITION)
  
  def edit
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @priorities = IssuePriority.all
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @time_entry = TimeEntry.new
    
    @notes = params[:notes]
    journal = @issue.init_journal(User.current, @notes)
    # User can change issue attributes only if he has :edit permission or if a workflow transition is allowed
    if (@edit_allowed || !@allowed_statuses.empty?) && params[:issue]
      attrs = params[:issue].dup
      attrs.delete_if {|k,v| !UPDATABLE_ATTRS_ON_TRANSITION.include?(k) } unless @edit_allowed
      attrs.delete(:status_id) unless @allowed_statuses.detect {|s| s.id.to_s == attrs[:status_id].to_s}
      @issue.attributes = attrs
    end

    if request.post?
      @issue.parent_id = params[:issue][:parent_id] if params[:issue] && params[:issue][:parent_id]

      @time_entry = TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => Date.today)
      @time_entry.attributes = params[:time_entry]
      attachments = attach_files(@issue, params[:attachments])
      attachments.each {|a| journal.details << JournalDetail.new(:property => 'attachment', :prop_key => a.id, :value => a.filename)}
      
      call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => @time_entry, :journal => journal})

      if (@time_entry.hours.nil? || @time_entry.valid?) && @issue.save
        # Log spend time
        if User.current.allowed_to?(:log_time, @project)
          @time_entry.save
        end
        if !journal.new_record?
          # Only send notification if something was actually changed
          flash[:notice] = l(:notice_successful_update)
        end
        call_hook(:controller_issues_edit_after_save, { :params => params, :issue => @issue, :time_entry => @time_entry, :journal => journal})
        redirect_to(params[:back_to] || {:action => 'show', :id => @issue})
      end
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
    # Remove the previously added attachments if issue was not updated
    attachments.each(&:destroy)
  end

  def add_subissue
    redirect_to :action => 'new',
                :project_id => @parent_issue.project,
                :issue => { :parent_id => @parent_issue.id }
  end
  
  def reply
    journal = Journal.find(params[:journal_id]) if params[:journal_id]
    if journal
      user = journal.user
      text = journal.notes
    else
      user = @issue.author
      text = @issue.description
    end
    content = "#{ll(Setting.default_language, :text_user_wrote, user)}\\n> "
    content << text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]').gsub('"', '\"').gsub(/(\r?\n|\r\n?)/, "\\n> ") + "\\n\\n"
    render(:update) { |page|
      page.<< "$('notes').value = \"#{content}\";"
      page.show 'update'
      page << "Form.Element.focus('notes');"
      page << "Element.scrollTo('update');"
      page << "$('notes').scrollTop = $('notes').scrollHeight - $('notes').clientHeight;"
    }
  end
  
  # Bulk edit a set of issues
  def bulk_edit
    if request.post?
      tracker = params[:tracker_id].blank? ? nil : @project.trackers.find_by_id(params[:tracker_id])
      status = params[:status_id].blank? ? nil : IssueStatus.find_by_id(params[:status_id])
      priority = params[:priority_id].blank? ? nil : IssuePriority.find_by_id(params[:priority_id])
      assigned_to = (params[:assigned_to_id].blank? || params[:assigned_to_id] == 'none') ? nil : User.find_by_id(params[:assigned_to_id])
      category = (params[:category_id].blank? || params[:category_id] == 'none') ? nil : @project.issue_categories.find_by_id(params[:category_id])
      fixed_version = (params[:fixed_version_id].blank? || params[:fixed_version_id] == 'none') ? nil : @project.shared_versions.find_by_id(params[:fixed_version_id])
      custom_field_values = params[:custom_field_values] ? params[:custom_field_values].reject {|k,v| v.blank?} : nil
      
      unsaved_issue_ids = []      
      @issues.each do |issue|
        journal = issue.init_journal(User.current, params[:notes])
        issue.tracker = tracker if tracker
        issue.priority = priority if priority
        issue.assigned_to = assigned_to if assigned_to || params[:assigned_to_id] == 'none'
        issue.category = category if category || params[:category_id] == 'none'
        issue.fixed_version = fixed_version if fixed_version || params[:fixed_version_id] == 'none'
        issue.start_date = params[:start_date] unless params[:start_date].blank?
        issue.due_date = params[:due_date] unless params[:due_date].blank?
        issue.done_ratio = params[:done_ratio] unless params[:done_ratio].blank?
        issue.custom_field_values = custom_field_values if custom_field_values && !custom_field_values.empty?
        call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })
        # Don't save any change to the issue if the user is not authorized to apply the requested status
        unless (status.nil? || (issue.new_statuses_allowed_to(User.current).include?(status) && issue.status = status)) && issue.save
          # Keep unsaved issue ids to display them in flash error
          unsaved_issue_ids << issue.id
        end
      end
      if unsaved_issue_ids.empty?
        flash[:notice] = l(:notice_successful_update) unless @issues.empty?
      else
        flash[:error] = l(:notice_failed_to_save_issues, :count => unsaved_issue_ids.size,
                                                         :total => @issues.size,
                                                         :ids => '#' + unsaved_issue_ids.join(', #'))
      end
      redirect_to(params[:back_to] || {:controller => 'issues', :action => 'index', :project_id => @project})
      return
    end
    @available_statuses = Workflow.available_statuses(@project)
    @custom_fields = @project.issue_custom_fields.select {|f| f.field_format == 'list'}
  end

  def move
    @copy = params[:copy_options] && params[:copy_options][:copy]
    @allowed_projects = []
    # find projects to which the user is allowed to move the issue
    if User.current.admin?
      # admin is allowed to move issues to any active (visible) project
      @allowed_projects = Project.find(:all, :conditions => Project.visible_by(User.current))
    else
      User.current.memberships.each {|m| @allowed_projects << m.project if m.roles.detect {|r| r.allowed_to?(:move_issues)}}
    end
    @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:new_project_id]} if params[:new_project_id]
    @target_project ||= @project    
    @trackers = @target_project.trackers
    @available_statuses = Workflow.available_statuses(@project)
    if request.post?
      new_tracker = params[:new_tracker_id].blank? ? nil : @target_project.trackers.find_by_id(params[:new_tracker_id])
      unsaved_issue_ids = []
      moved_issues = []
      @issues.each do |issue|
        changed_attributes = {}
        [:assigned_to_id, :status_id, :start_date, :due_date].each do |valid_attribute|
          unless params[valid_attribute].blank?
            changed_attributes[valid_attribute] = (params[valid_attribute] == 'none' ? nil : params[valid_attribute])
          end 
        end
        issue.init_journal(User.current)
        if r = issue.move_to(@target_project, new_tracker, {:copy => @copy, :attributes => changed_attributes})
          moved_issues << r
        else
          unsaved_issue_ids << issue.id
        end
      end
      if unsaved_issue_ids.empty?
        flash[:notice] = l(:notice_successful_update) unless @issues.empty?
      else
        flash[:error] = l(:notice_failed_to_save_issues, :count => unsaved_issue_ids.size,
                                                         :total => @issues.size,
                                                         :ids => '#' + unsaved_issue_ids.join(', #'))
      end
      if params[:follow]
        if @issues.size == 1 && moved_issues.size == 1
          redirect_to :controller => 'issues', :action => 'show', :id => moved_issues.first
        else
          redirect_to :controller => 'issues', :action => 'index', :project_id => (@target_project || @project)
        end
      else
        redirect_to :controller => 'issues', :action => 'index', :project_id => @project
      end
      return
    end
    render :layout => false if request.xhr?
  end
  
  def destroy
    @hours = TimeEntry.sum(:hours, :conditions => ['issue_id IN (?)', @issues]).to_f
    if @hours > 0
      case params[:todo]
      when 'destroy'
        # nothing to do
      when 'nullify'
        TimeEntry.update_all('issue_id = NULL', ['issue_id IN (?)', @issues])
      when 'reassign'
        reassign_to = @project.issues.find_by_id(params[:reassign_to_id])
        if reassign_to.nil?
          flash.now[:error] = l(:error_issue_not_found_in_project)
          return
        else
          TimeEntry.update_all("issue_id = #{reassign_to.id}", ['issue_id IN (?)', @issues])
        end
      else
        # display the destroy form
        return
      end
    end
    @issues.each(&:destroy)
    redirect_to :action => 'index', :project_id => @project
  end
  
  def gantt
    @gantt = Redmine::Helpers::Gantt.new(params)
    retrieve_query
    if @query.valid?
      events = []
      # Issues that have start and due dates
      events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :order => "start_date, due_date",
                              :conditions => ["(((start_date>=? and start_date<=?) or (due_date>=? and due_date<=?) or (start_date<? and due_date>?)) and start_date is not null and due_date is not null)", @gantt.date_from, @gantt.date_to, @gantt.date_from, @gantt.date_to, @gantt.date_from, @gantt.date_to]
                              )
      # Issues that don't have a due date but that are assigned to a version with a date
      events += @query.issues(:include => [:tracker, :assigned_to, :priority, :fixed_version],
                              :order => "start_date, effective_date",
                              :conditions => ["(((start_date>=? and start_date<=?) or (effective_date>=? and effective_date<=?) or (start_date<? and effective_date>?)) and start_date is not null and due_date is null and effective_date is not null)", @gantt.date_from, @gantt.date_to, @gantt.date_from, @gantt.date_to, @gantt.date_from, @gantt.date_to]
                              )
      # Parent issues that might not have the due_date set but do have
      # child issues that do have due_date set should be included.
      events.each do |issue|
        if issue.leaf?
          # Can't use the Issue#visible named_scope because it causes
          # a SQL error with the awesome_nested_set
          ancestors = issue.ancestors.all(:include => [:tracker, :assigned_to, :priority, :project],
                                          :order => "start_date",
                                          :conditions => 'start_date IS NOT NULL')
          ancestors.map! {|i| i.visible? ? i : nil }.compact!

          events += ancestors.flatten if ancestors.present?
        end
      end
      
      # Versions
      events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @gantt.date_from, @gantt.date_to])

      @gantt.events = events.uniq
    end
    
    basename = (@project ? "#{@project.identifier}-" : '') + 'gantt'
    
    respond_to do |format|
      format.html { render :template => "issues/gantt.rhtml", :layout => !request.xhr? }
      format.png  { send_data(@gantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @gantt.respond_to?('to_image')
      format.pdf  { send_data(gantt_to_pdf(@gantt, @project), :type => 'application/pdf', :filename => "#{basename}.pdf") }
    end
  end
  
  def calendar
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end    
    end
    @year ||= Date.today.year
    @month ||= Date.today.month
    
    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    retrieve_query
    if @query.valid?
      events = []
      events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                              )
      events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])
                                     
      @calendar.events = events
    end
    
    render :layout => false if request.xhr?
  end
  
  def context_menu
    @issues = Issue.find_all_by_id(params[:ids], :include => :project)
    if (@issues.size == 1)
      @issue = @issues.first
      @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    end
    projects = @issues.collect(&:project).compact.uniq
    @project = projects.first if projects.size == 1

    @can = {:edit => (@project && User.current.allowed_to?(:edit_issues, @project)),
            :log_time => (@project && User.current.allowed_to?(:log_time, @project)),
            :update => (@project && (User.current.allowed_to?(:edit_issues, @project) || (User.current.allowed_to?(:change_status, @project) && @allowed_statuses && !@allowed_statuses.empty?))),
            :move => (@project && User.current.allowed_to?(:move_issues, @project)),
            :copy => (@issue && @project.trackers.include?(@issue.tracker) && User.current.allowed_to?(:add_issues, @project)),
            :delete => (@project && User.current.allowed_to?(:delete_issues, @project))
            }
    if @project
      @assignables = @project.assignable_users
      @assignables << @issue.assigned_to if @issue && @issue.assigned_to && !@assignables.include?(@issue.assigned_to)
      @trackers = @project.trackers
    end
    
    @priorities = IssuePriority.all.reverse
    @statuses = IssueStatus.find(:all, :order => 'position')
    @back = params[:back_url] || request.env['HTTP_REFERER']
    
    render :layout => false
  end

  def update_form
    if params[:id].blank?
      @issue = Issue.new
      @issue.project = @project
    else
      @issue = @project.issues.visible.find(params[:id])
    end
    @issue.attributes = params[:issue]
    @allowed_statuses = ([@issue.status] + @issue.status.find_new_statuses_allowed_to(User.current.roles_for_project(@project), @issue.tracker)).uniq
    @priorities = IssuePriority.all
    
    render :partial => 'attributes'
  end
  
  def preview
    @issue = @project.issues.find_by_id(params[:id]) unless params[:id].blank?
    @attachements = @issue.attachments if @issue
    @text = params[:notes] || (params[:issue] ? params[:issue][:description] : nil)
    render :partial => 'common/preview'
  end

  def auto_complete_for_issue_parent
    @phrase = params[:issue_parent]
    @candidates = []

    # If cross project issue relations is allowed we should get
    # candidates from every project
    if Setting.cross_project_issue_relations?
      projects_to_search = nil
    else
      projects_to_search = [ @project ] + @project.children
    end

    if @phrase.present?
      # Try to find issue by id.
      if @phrase.match(/^#?(\d+)$/)
        if Setting.cross_project_issue_relations?
          issue = Issue.visible.find_by_id( $1)
        else
          issue = Issue.visible.find_by_id_and_project_id( $1, projects_to_search.collect { |i| i.id})
        end
        @candidates << issue if issue
      end

      # Search by subject and description
      # extract tokens from the question
      # eg. hello "bye bye" => ["hello", "bye bye"]
      tokens = @phrase.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
      # tokens must be at least 3 character long
      tokens = tokens.uniq.select {|w| w.length > 2 }
      like_tokens = tokens.collect {|w| "%#{w.downcase}%"}

      search_results, count = Issue.search( like_tokens, projects_to_search, :before => true, :limit => 10)
      @candidates += search_results unless search_results.empty?
    end

    # Remove the current issue if it's a result
    if params[:id].present?
      @issue = Issue.visible.find_by_id(params[:id]) 
      @candidates.delete(@issue)
    end

    render :inline => "<%= auto_complete_result_parent_issue( @candidates, @phrase) %>"
  end
  
private
  def find_issue
    @issue = Issue.find(params[:id], :include => [:project, :tracker, :status, :author, :priority, :category])
    @project = @issue.project
    @parent_issue = @issue.parent if @issue
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_parent_issue
    @parent_issue = Issue.find( params[:parent_issue_id])
    render_404 unless @parent_issue.visible?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_parent_issue
    if params[:issue] && !params[:issue][:parent_id].blank?
      @parent_issue = Issue.visible.find_by_id( params[:issue][:parent_id])
    end
  end
  
  # Filter for bulk operations
  def find_issues
    @issues = Issue.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @issues.empty?
    projects = @issues.collect(&:project).compact.uniq
    if projects.size == 1
      @project = projects.first
    else
      # TODO: let users bulk edit/move/destroy issues from different projects
      render_error 'Can not bulk edit/move/destroy issues from different projects'
      return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  # Retrieve query from session or build a new query
  def retrieve_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = Query.find(params[:query_id], :conditions => cond)
      @query.project = @project
      session[:query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    else
      if params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
        # Give it a name, required to be valid
        @query = Query.new(:name => "_")
        @query.project = @project
        if params[:fields] and params[:fields].is_a? Array
          params[:fields].each do |field|
            @query.add_filter(field, params[:operators][field], params[:values][field])
          end
        else
          @query.available_filters.keys.each do |field|
            @query.add_short_filter(field, params[field]) if params[field]
          end
        end
        @query.group_by = params[:group_by]
        @query.column_names = params[:query] && params[:query][:column_names]
        if params[:view_options] and params[:view_options].is_a? Hash
          params[:view_options].each_pair do |name, value|
            @query.set_view_option( name, value)
          end
        end
        
        session[:query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names, :view_options => @query.view_options}
      else
        @query = Query.find_by_id(session[:query][:id]) if session[:query][:id]
        @query ||= Query.new(:name => "_", :project => @project, :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names])
        if session[:query][:view_options]
          session[:query][:view_options].each_pair do |name, value|
            @query.set_view_option( name, value)
          end
        end
        @query.project = @project
      end
    end
  end

  # Retrive and build a query for the subissues
  def retrieve_query_for_subissues
    retrieve_query
    @query.project = @project
    @query.set_view_option('show_parents', ViewOption::SHOW_PARENTS[:organize_by])
    @query.column_names = Setting.subissues_list_columns
    sort_init( @query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update({'id' => "#{Issue.table_name}.id"}.merge( @query.available_columns.inject({}) { |h, c| h[c.name.to_s] = c.sortable; h}))

  end
  
  # Rescues an invalid query statement. Just in case...
  def query_statement_invalid(exception)
    logger.error "Query::StatementInvalid: #{exception.message}" if logger
    session.delete(:query)
    sort_clear
    render_error "An error occurred while executing the query and has been logged. Please report this error to your Redmine administrator."
  end
end
