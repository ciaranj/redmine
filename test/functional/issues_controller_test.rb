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

require File.dirname(__FILE__) + '/../test_helper'
require 'issues_controller'

# Re-raise errors caught by the controller.
class IssuesController; def rescue_action(e) raise e end; end

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries
  
  def setup
    @controller = IssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_index_routing
    assert_routing(
      {:method => :get, :path => '/issues'},
      :controller => 'issues', :action => 'index'
    )
  end

  def test_index
    Setting.default_language = 'en'
    
    get :index
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
    # private projects hidden
    assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
    assert_no_tag :tag => 'a', :content => /Issue on project 2/
    # project column
    assert_tag :tag => 'th', :content => /Project/
  end
  
  def test_index_should_not_list_issues_when_module_disabled
    EnabledModule.delete_all("name = 'issue_tracking' AND project_id = 1")
    get :index
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_no_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
  end

  def test_index_with_project_routing
    assert_routing(
      {:method => :get, :path => '/projects/23/issues'},
      :controller => 'issues', :action => 'index', :project_id => '23'
    )
  end
  
  def test_index_should_not_list_issues_when_module_disabled
    EnabledModule.delete_all("name = 'issue_tracking' AND project_id = 1")
    get :index
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_no_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
  end

  def test_index_with_project_routing
    assert_routing(
      {:method => :get, :path => 'projects/23/issues'},
      :controller => 'issues', :action => 'index', :project_id => '23'
    )
  end
  
  def test_index_with_project
    Setting.display_subprojects_issues = 0
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => /Can't print recipes/
    assert_no_tag :tag => 'a', :content => /Subproject issue/
  end
  
  def test_index_with_project_and_subprojects
    Setting.display_subprojects_issues = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
    assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
  end
  
  def test_index_with_project_and_subprojects_should_show_private_subprojects
    @request.session[:user_id] = 2
    Setting.display_subprojects_issues = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
    assert_tag :tag => 'a', :content => /Issue of a private subproject/
  end
  
  def test_index_with_project_routing_formatted
    assert_routing(
      {:method => :get, :path => 'projects/23/issues.pdf'},
      :controller => 'issues', :action => 'index', :project_id => '23', :format => 'pdf'
    )
    assert_routing(
      {:method => :get, :path => 'projects/23/issues.atom'},
      :controller => 'issues', :action => 'index', :project_id => '23', :format => 'atom'
    )
  end
  
  def test_index_with_project_and_filter
    get :index, :project_id => 1, :set_filter => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
  end
  
  def test_index_with_query
    get :index, :project_id => 1, :query_id => 5
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:issue_count_by_group)
  end
  
  def test_index_with_query_grouped_by_tracker
    get :index, :project_id => 1, :query_id => 6
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
  end
  
  def test_index_with_query_grouped_by_list_custom_field
    get :index, :project_id => 1, :query_id => 9
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
  end
  
  def test_index_sort_by_field_not_included_in_columns
    Setting.issue_list_default_columns = %w(subject author)
    get :index, :sort => 'tracker'
  end
  
  def test_index_csv_with_project
    Setting.default_language = 'en'
    
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv', @response.content_type
    assert @response.body.starts_with?("#,")

    get :index, :project_id => 1, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv', @response.content_type
  end
  
  def test_index_formatted
    assert_routing(
      {:method => :get, :path => 'issues.pdf'},
      :controller => 'issues', :action => 'index', :format => 'pdf'
    )
    assert_routing(
      {:method => :get, :path => 'issues.atom'},
      :controller => 'issues', :action => 'index', :format => 'atom'
    )
  end
  
  def test_index_pdf
    get :index, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
    
    get :index, :project_id => 1, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
    
    get :index, :project_id => 1, :query_id => 6, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
  end
  
  def test_index_pdf_with_query_grouped_by_list_custom_field
    get :index, :project_id => 1, :query_id => 9, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
    assert_equal 'application/pdf', @response.content_type
  end
  
  def test_index_sort
    get :index, :sort => 'tracker,id:desc'
    assert_response :success
    
    sort_params = @request.session['issues_index_sort']
    assert sort_params.is_a?(String)
    assert_equal 'tracker,id:desc', sort_params
    
    issues = assigns(:issues)
    assert_not_nil issues
    assert !issues.empty?
    assert_equal issues.sort {|a,b| a.tracker == b.tracker ? b.id <=> a.id : a.tracker <=> b.tracker }.collect(&:id), issues.collect(&:id)
  end
  
  def test_index_with_columns
    columns = ['tracker', 'subject', 'assigned_to']
    get :index, :set_filter => 1, :query => { 'column_names' => columns}
    assert_response :success
    
    # query should use specified columns
    query = assigns(:query)
    assert_kind_of Query, query
    assert_equal columns, query.column_names.map(&:to_s)
    
    # columns should be stored in session
    assert_kind_of Hash, session[:query]
    assert_kind_of Array, session[:query][:column_names]
    assert_equal columns, session[:query][:column_names].map(&:to_s)
  end

  def test_gantt
    parent_issue = Issue.find(14)
    parent_issue.update_attributes(:start_date => 1.day.ago.to_date)
    parent_issue.reload
    assert_not_nil parent_issue.due_date
    assert_nil parent_issue.read_attribute(:due_date)

    subissue = Issue.generate_for_project!(Project.find(1), :start_date => 1.day.ago.to_date, :due_date => 10.days.from_now.to_date)
    subissue.move_to_child_of Issue.find(14)

    get :gantt, :project_id => 1
    assert_response :success
    assert_template 'gantt.rhtml'
    assert_not_nil assigns(:gantt)
    events = assigns(:gantt).events
    assert_not_nil events
    # Issue with start and due dates
    assert events.include?(subissue)
    i = Issue.find(1)
    assert_not_nil i.due_date
    assert events.include?(Issue.find(1))
    # Parent issue with a child with a start and due date
    assert events.include?(Issue.find(14))
    # Issue with without due date but targeted to a version with date
    i = Issue.find(2)
    assert_nil i.due_date
    assert events.include?(i)
  end

  def test_cross_project_gantt
    get :gantt
    assert_response :success
    assert_template 'gantt.rhtml'
    assert_not_nil assigns(:gantt)
    events = assigns(:gantt).events
    assert_not_nil events
  end

  def test_gantt_export_to_pdf
    get :gantt, :project_id => 1, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
    assert_not_nil assigns(:gantt)
  end

  def test_cross_project_gantt_export_to_pdf
    get :gantt, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
    assert_not_nil assigns(:gantt)
  end
  
  if Object.const_defined?(:Magick)
    def test_gantt_image
      get :gantt, :project_id => 1, :format => 'png'
      assert_response :success
      assert_equal 'image/png', @response.content_type
    end
  else
    puts "RMagick not installed. Skipping tests !!!"
  end
  
  def test_calendar
    get :calendar, :project_id => 1
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end
  
  def test_cross_project_calendar
    get :calendar
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end
  
  def test_changes
    get :changes, :project_id => 1
    assert_response :success
    assert_not_nil assigns(:journals)
    assert_equal 'application/atom+xml', @response.content_type
  end
  
  def test_show_routing
    assert_routing(
      {:method => :get, :path => '/issues/64'},
      :controller => 'issues', :action => 'show', :id => '64'
    )
  end
  
  def test_show_routing_formatted
    assert_routing(
      {:method => :get, :path => '/issues/2332.pdf'},
      :controller => 'issues', :action => 'show', :id => '2332', :format => 'pdf'
    )
    assert_routing(
      {:method => :get, :path => '/issues/23123.atom'},
      :controller => 'issues', :action => 'show', :id => '23123', :format => 'atom'
    )
  end
  
  def test_show_by_anonymous
    get :show, :id => 1
    assert_response :success
    assert_template 'show.rhtml'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)
    
    # anonymous role is allowed to add a note
    assert_tag :tag => 'form',
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Notes/ } }
  end
  
  def test_show_by_manager
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success
    
    assert_tag :tag => 'form',
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Change properties/ } },
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Log time/ } },
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Notes/ } }
  end
  
  def test_show_should_deny_anonymous_access_without_permission
    Role.anonymous.remove_permission!(:view_issues)
    get :show, :id => 1
    assert_response :redirect
  end
  
  def test_show_should_deny_non_member_access_without_permission
    Role.non_member.remove_permission!(:view_issues)
    @request.session[:user_id] = 9
    get :show, :id => 1
    assert_response 403
  end
  
  def test_show_should_deny_member_access_without_permission
    Role.find(1).remove_permission!(:view_issues)
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response 403
  end
  
  def test_show_should_not_disclose_relations_to_invisible_issues
    Setting.cross_project_issue_relations = '1'
    IssueRelation.create!(:issue_from => Issue.find(1), :issue_to => Issue.find(2), :relation_type => 'relates')
    # Relation to a private project issue
    IssueRelation.create!(:issue_from => Issue.find(1), :issue_to => Issue.find(4), :relation_type => 'relates')
    
    get :show, :id => 1
    assert_response :success
    
    assert_tag :div, :attributes => { :id => 'relations' },
                     :descendant => { :tag => 'a', :content => /#2$/ }
    assert_no_tag :div, :attributes => { :id => 'relations' },
                        :descendant => { :tag => 'a', :content => /#4$/ }
  end
  
  def test_show_atom
    get :show, :id => 2, :format => 'atom'
    assert_response :success
    assert_template 'changes.rxml'
    # Inline image
    assert @response.body.include?("&lt;img src=\"http://test.host/attachments/download/10\" alt=\"\" /&gt;"), "Body did not match. Body: #{@response.body}"
  end
  
  def test_new_routing
    assert_routing(
      {:method => :get, :path => '/projects/1/issues/new'},
      :controller => 'issues', :action => 'new', :project_id => '1'
    )
    assert_recognizes(
      {:controller => 'issues', :action => 'new', :project_id => '1'},
      {:method => :post, :path => '/projects/1/issues'}
    )
  end

  def test_show_export_to_pdf
    get :show, :id => 3, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
    assert_not_nil assigns(:issue)
  end

  def test_get_new
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success
    assert_template 'new'
    
    assert_tag :tag => 'input', :attributes => { :name => 'issue[custom_field_values][2]',
                                                 :value => 'Default string' }
  end

  def test_get_new_without_tracker_id
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    
    issue = assigns(:issue)
    assert_not_nil issue
    assert_equal Project.find(1).trackers.first, issue.tracker
  end
  
  def test_get_new_with_no_default_status_should_display_an_error
    @request.session[:user_id] = 2
    IssueStatus.delete_all
    
    get :new, :project_id => 1
    assert_response 500
    assert_not_nil flash[:error]
    assert_tag :tag => 'div', :attributes => { :class => /error/ },
                              :content => /No default issue/
  end
  
  def test_get_new_with_no_tracker_should_display_an_error
    @request.session[:user_id] = 2
    Tracker.delete_all
    
    get :new, :project_id => 1
    assert_response 500
    assert_not_nil flash[:error]
    assert_tag :tag => 'div', :attributes => { :class => /error/ },
                              :content => /No tracker/
  end

  context "GET to :new" do
    context "with a parent_id" do
      setup do
        @request.session[:user_id] = 3
      end

      should "set the parent issue" do
        get :new, :project_id => 1, :issue => {:parent_id => 1}
        assert_response :success
        assert_template 'new'
        assert_equal Issue.find(1), assigns(:parent_issue)
      end

      should "not set the parent issue if the parameter points to a missing issue" do
        get :new, :project_id => 1, :issue => {:parent_id => 1_000_000}
        assert_response :success
        assert_template 'new'
        assert_equal nil, assigns(:parent_issue)
      end

      should "not set the parent issue if the parameter points to an unauthorized issue" do
        issue = Issue.generate_for_project!(Project.find(5))
        get :new, :project_id => 1, :issue => {:parent_id => issue.id}
        assert_response :success
        assert_template 'new'
        assert_equal nil, assigns(:parent_issue)
      end
    end

  end

  def test_update_new_form
    @request.session[:user_id] = 2
    xhr :post, :update_form, :project_id => 1,
                     :issue => {:tracker_id => 2, 
                                :subject => 'This is the test_new issue',
                                :description => 'This is the description',
                                :priority_id => 5}
    assert_response :success
    assert_template 'attributes'
    
    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 'This is the test_new issue', issue.subject
  end
  
  def test_post_new
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 3,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
    
    issue = Issue.find_by_subject('This is the test_new issue')
    assert_not_nil issue
    assert_equal 2, issue.author_id
    assert_equal 3, issue.tracker_id
    assert_nil issue.estimated_hours
    v = issue.custom_values.find(:first, :conditions => {:custom_field_id => 2})
    assert_not_nil v
    assert_equal 'Value for field 2', v.value
  end
  
  def test_post_new_and_continue
    @request.session[:user_id] = 2
    post :new, :project_id => 1, 
               :issue => {:tracker_id => 3,
                          :subject => 'This is first issue',
                          :priority_id => 5},
               :continue => ''
    assert_redirected_to :controller => 'issues', :action => 'new', :tracker_id => 3
  end
  
  def test_post_new_without_custom_fields_param
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 1,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
  end

  def test_post_new_with_required_custom_field_and_without_custom_fields_param
    field = IssueCustomField.find_by_name('Database')
    field.update_attribute(:is_required, true)

    @request.session[:user_id] = 2
    post :new, :project_id => 1, 
               :issue => {:tracker_id => 1,
                          :subject => 'This is the test_new issue',
                          :description => 'This is the description',
                          :priority_id => 5}
    assert_response :success
    assert_template 'new'
    issue = assigns(:issue)
    assert_not_nil issue
    assert_equal I18n.translate('activerecord.errors.messages.invalid'), issue.errors.on(:custom_values)
  end
  
  def test_post_new_with_watchers
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    
    assert_difference 'Watcher.count', 2 do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a new issue with watchers',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :watcher_user_ids => ['2', '3']}
    end
    issue = Issue.find_by_subject('This is a new issue with watchers')
    assert_not_nil issue
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue
    
    # Watchers added
    assert_equal [2, 3], issue.watcher_user_ids.sort
    assert issue.watched_by?(User.find(3))
    # Watchers notified
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert [mail.bcc, mail.cc].flatten.include?(User.find(3).mail)
  end
  
  def test_post_new_should_send_a_notification
    ActionMailer::Base.deliveries.clear
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 3,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
    
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  def test_post_should_preserve_fields_values_on_validation_failure
    @request.session[:user_id] = 2
    post :new, :project_id => 1, 
               :issue => {:tracker_id => 1,
                          # empty subject
                          :subject => '',
                          :description => 'This is a description',
                          :priority_id => 6,
                          :custom_field_values => {'1' => 'Oracle', '2' => 'Value for field 2'}}
    assert_response :success
    assert_template 'new'
    
    assert_tag :textarea, :attributes => { :name => 'issue[description]' },
                          :content => 'This is a description'
    assert_tag :select, :attributes => { :name => 'issue[priority_id]' },
                        :child => { :tag => 'option', :attributes => { :selected => 'selected',
                                                                       :value => '6' },
                                                      :content => 'High' }  
    # Custom fields
    assert_tag :select, :attributes => { :name => 'issue[custom_field_values][1]' },
                        :child => { :tag => 'option', :attributes => { :selected => 'selected',
                                                                       :value => 'Oracle' },
                                                      :content => 'Oracle' }  
    assert_tag :input, :attributes => { :name => 'issue[custom_field_values][2]',
                                        :value => 'Value for field 2'}
  end
  
  def test_copy_routing
    assert_routing(
      {:method => :get, :path => '/projects/world_domination/issues/567/copy'},
      :controller => 'issues', :action => 'new', :project_id => 'world_domination', :copy_from => '567'
    )
  end
  
  def test_copy_issue
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :copy_from => 1
    assert_template 'new'
    assert_not_nil assigns(:issue)
    orig = Issue.find(1)
    assert_equal orig.subject, assigns(:issue).subject
  end
  
  def test_edit_routing
    assert_routing(
      {:method => :get, :path => '/issues/1/edit'},
      :controller => 'issues', :action => 'edit', :id => '1'
    )
    assert_recognizes( #TODO: use a PUT on the issue URI isntead, need to adjust form
      {:controller => 'issues', :action => 'edit', :id => '1'},
      {:method => :post, :path => '/issues/1/edit'}
    )
  end
  
  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)
  end
  
  def test_get_edit_with_params
    @request.session[:user_id] = 2
    get :edit, :id => 1, :issue => { :status_id => 5, :priority_id => 7 }
    assert_response :success
    assert_template 'edit'
    
    issue = assigns(:issue)
    assert_not_nil issue
    
    assert_equal 5, issue.status_id
    assert_tag :select, :attributes => { :name => 'issue[status_id]' },
                        :child => { :tag => 'option', 
                                    :content => 'Closed',
                                    :attributes => { :selected => 'selected' } }
                                    
    assert_equal 7, issue.priority_id
    assert_tag :select, :attributes => { :name => 'issue[priority_id]' },
                        :child => { :tag => 'option', 
                                    :content => 'Urgent',
                                    :attributes => { :selected => 'selected' } }
  end

  def test_update_edit_form
    @request.session[:user_id] = 2
    xhr :post, :update_form, :project_id => 1,
                             :id => 1,
                             :issue => {:tracker_id => 2, 
                                        :subject => 'This is the test_new issue',
                                        :description => 'This is the description',
                                        :priority_id => 5}
    assert_response :success
    assert_template 'attributes'
    
    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.id
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 'This is the test_new issue', issue.subject
  end
  
  def test_reply_routing
    assert_routing(
      {:method => :post, :path => '/issues/1/quoted'},
      :controller => 'issues', :action => 'reply', :id => '1'
    )
  end
  
  def test_reply_to_issue
    @request.session[:user_id] = 2
    get :reply, :id => 1
    assert_response :success
    assert_select_rjs :show, "update"
  end

  def test_reply_to_note
    @request.session[:user_id] = 2
    get :reply, :id => 1, :journal_id => 2
    assert_response :success
    assert_select_rjs :show, "update"
  end

  def test_post_edit_without_custom_fields_param
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    
    issue = Issue.find(1)
    assert_equal '125', issue.custom_value_for(2).value
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'
    
    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 2) do
        post :edit, :id => 1, :issue => {:subject => new_subject,
                                         :priority_id => '6',
                                         :category_id => '1' # no change
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal new_subject, issue.subject
    # Make sure custom fields were not cleared
    assert_equal '125', issue.custom_value_for(2).value
    
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}]")
    assert mail.body.include?("Subject changed from #{old_subject} to #{new_subject}")
  end
  
  def test_post_edit_with_custom_field_change
    @request.session[:user_id] = 2
    issue = Issue.find(1)
    assert_equal '125', issue.custom_value_for(2).value
    
    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 3) do
        post :edit, :id => 1, :issue => {:subject => 'Custom field change',
                                         :priority_id => '6',
                                         :category_id => '1', # no change
                                         :custom_field_values => { '2' => 'New custom value' }
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal 'New custom value', issue.custom_value_for(2).value
    
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert mail.body.include?("Searchable field changed from 125 to New custom value")
  end
  
  def test_post_edit_with_status_and_assignee_change
    issue = Issue.find(1)
    assert_equal 1, issue.status_id
    @request.session[:user_id] = 2
    assert_difference('TimeEntry.count', 0) do
      post :edit,
           :id => 1,
           :issue => { :status_id => 2, :assigned_to_id => 3 },
           :notes => 'Assigned to dlopper',
           :time_entry => { :hours => '', :comments => '', :activity_id => TimeEntryActivity.first }
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal 2, issue.status_id
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal 'Assigned to dlopper', j.notes
    assert_equal 2, j.details.size
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?("Status changed from New to Assigned")
    # subject should contain the new status
    assert mail.subject.include?("(#{ IssueStatus.find(2).name })")
  end
  
  def test_post_edit_with_note_only
    notes = 'Note added by IssuesControllerTest#test_update_with_note_only'
    # anonymous user
    post :edit,
         :id => 1,
         :notes => notes
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal notes, j.notes
    assert_equal 0, j.details.size
    assert_equal User.anonymous, j.user
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?(notes)
  end
  
  def test_post_edit_with_note_and_spent_time
    @request.session[:user_id] = 2
    spent_hours_before = Issue.find(1).spent_hours
    assert_difference('TimeEntry.count') do
      post :edit,
           :id => 1,
           :notes => '2.5 hours added',
           :time_entry => { :hours => '2.5', :comments => '', :activity_id => TimeEntryActivity.first }
    end
    assert_redirected_to :action => 'show', :id => '1'
    
    issue = Issue.find(1)
    
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal '2.5 hours added', j.notes
    assert_equal 0, j.details.size
    
    t = issue.time_entries.find(:first, :order => 'id DESC')
    assert_not_nil t
    assert_equal 2.5, t.hours
    assert_equal spent_hours_before + 2.5, issue.spent_hours
  end
  
  def test_post_edit_with_attachment_only
    set_tmp_attachments_directory
    
    # Delete all fixtured journals, a race condition can occur causing the wrong
    # journal to get fetched in the next find.
    Journal.delete_all

    # anonymous user
    post :edit,
         :id => 1,
         :notes => '',
         :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    assert_redirected_to :action => 'show', :id => '1'
    j = Issue.find(1).journals.find(:first, :order => 'id DESC')
    assert j.notes.blank?
    assert_equal 1, j.details.size
    assert_equal 'testfile.txt', j.details.first.value
    assert_equal User.anonymous, j.user
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?('testfile.txt')
  end
  
  def test_post_edit_with_no_change
    issue = Issue.find(1)
    issue.journals.clear
    ActionMailer::Base.deliveries.clear
    
    post :edit,
         :id => 1,
         :notes => ''
    assert_redirected_to :action => 'show', :id => '1'
    
    issue.reload
    assert issue.journals.empty?
    # No email should be sent
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_post_edit_should_send_a_notification
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(1)
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'
    
    post :edit, :id => 1, :issue => {:subject => new_subject,
                                     :priority_id => '6',
                                     :category_id => '1' # no change
                                    }
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  def test_post_edit_with_invalid_spent_time
    @request.session[:user_id] = 2
    notes = 'Note added by IssuesControllerTest#test_post_edit_with_invalid_spent_time'
    
    assert_no_difference('Journal.count') do
      post :edit,
           :id => 1,
           :notes => notes,
           :time_entry => {"comments"=>"", "activity_id"=>"", "hours"=>"2z"}
    end
    assert_response :success
    assert_template 'edit'
    
    assert_tag :textarea, :attributes => { :name => 'notes' },
                          :content => notes
    assert_tag :input, :attributes => { :name => 'time_entry[hours]', :value => "2z" }
  end

  def test_post_edit_with_parent_id_set_to_self
    issue = Issue.find(1)
    assert_equal nil, issue.parent
    @request.session[:user_id] = 2

    post :edit,
         :id => 1,
         :issue => { :parent_id => 1}

    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal nil, issue.parent
  end
  
  def test_post_edit_should_allow_fixed_version_to_be_set_to_a_subproject
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    post :edit,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         }

    assert_response :redirect
    issue.reload
    assert_equal 4, issue.fixed_version_id
    assert_not_equal issue.project_id, issue.fixed_version.project_id
  end

  def test_post_edit_should_redirect_back_using_the_back_url_parameter
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    post :edit,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         },
         :back_url => '/issues'

    assert_response :redirect
    assert_redirected_to '/issues'
  end
  
  def test_post_edit_should_not_redirect_back_using_the_back_url_parameter_off_the_host
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    post :edit,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         },
         :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue.id
  end
  
  def test_get_bulk_edit
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'
    
    # Project specific custom field, date type
    field = CustomField.find(9)
    assert !field.is_for_all?
    assert_equal 'date', field.field_format
    assert_tag :input, :attributes => {:name => 'custom_field_values[9]'}
    
    # System wide custom field
    assert CustomField.find(1).is_for_all?
    assert_tag :select, :attributes => {:name => 'custom_field_values[1]'}
  end

  def test_bulk_edit
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_edit, :ids => [1, 2], :priority_id => 7,
                                     :assigned_to_id => '',
                                     :custom_field_values => {'2' => ''},
                                     :notes => 'Bulk editing'
    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7], Issue.find_all_by_id([1, 2]).collect {|i| i.priority.id}
    
    issue = Issue.find(1)
    journal = issue.journals.find(:first, :order => 'created_on DESC')
    assert_equal '125', issue.custom_value_for(2).value
    assert_equal 'Bulk editing', journal.notes
    assert_equal 1, journal.details.size
  end

  def test_bullk_edit_should_send_a_notification
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    post(:bulk_edit,
         {
           :ids => [1, 2],
           :priority_id => 7,
           :assigned_to_id => '',
           :custom_field_values => {'2' => ''},
           :notes => 'Bulk editing'
         })

    assert_response 302
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_bulk_edit_status
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_edit, :ids => [1, 2], :priority_id => '',
                                     :assigned_to_id => '',
                                     :status_id => '5',
                                     :notes => 'Bulk editing status'
    assert_response 302
    issue = Issue.find(1)
    assert issue.closed?
  end

  def test_bulk_edit_custom_field
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_edit, :ids => [1, 2], :priority_id => '',
                                     :assigned_to_id => '',
                                     :custom_field_values => {'2' => '777'},
                                     :notes => 'Bulk editing custom field'
    assert_response 302
    
    issue = Issue.find(1)
    journal = issue.journals.find(:first, :order => 'created_on DESC')
    assert_equal '777', issue.custom_value_for(2).value
    assert_equal 1, journal.details.size
    assert_equal '125', journal.details.first.old_value
    assert_equal '777', journal.details.first.value
  end

  def test_bulk_unassign
    assert_not_nil Issue.find(2).assigned_to
    @request.session[:user_id] = 2
    # unassign issues
    post :bulk_edit, :ids => [1, 2], :notes => 'Bulk unassigning', :assigned_to_id => 'none'
    assert_response 302
    # check that the issues were updated
    assert_nil Issue.find(2).assigned_to
  end
  
  def test_post_bulk_edit_should_allow_fixed_version_to_be_set_to_a_subproject
    @request.session[:user_id] = 2

    post :bulk_edit,
         :ids => [1,2],
         :fixed_version_id => 4

    assert_response :redirect
    issues = Issue.find([1,2])
    issues.each do |issue|
      assert_equal 4, issue.fixed_version_id
      assert_not_equal issue.project_id, issue.fixed_version.project_id
    end
  end

  def test_post_bulk_edit_should_redirect_back_using_the_back_url_parameter
    @request.session[:user_id] = 2
    post :bulk_edit, :ids => [1,2], :back_url => '/issues'

    assert_response :redirect
    assert_redirected_to '/issues'
  end

  def test_post_bulk_edit_should_not_redirect_back_using_the_back_url_parameter_off_the_host
    @request.session[:user_id] = 2
    post :bulk_edit, :ids => [1,2], :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => Project.find(1).identifier
  end

  def test_move_routing
    assert_routing(
      {:method => :get, :path => '/issues/1/move'},
      :controller => 'issues', :action => 'move', :id => '1'
    )
    assert_recognizes(
      {:controller => 'issues', :action => 'move', :id => '1'},
      {:method => :post, :path => '/issues/1/move'}
    )
  end
  
  def test_move_one_issue_to_another_project
    @request.session[:user_id] = 2
    post :move, :id => 1, :new_project_id => 2, :tracker_id => '', :assigned_to_id => '', :status_id => '', :start_date => '', :due_date => ''
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_equal 2, Issue.find(1).project_id
  end

  def test_move_one_issue_to_another_project_should_follow_when_needed
    @request.session[:user_id] = 2
    post :move, :id => 1, :new_project_id => 2, :follow => '1'
    assert_redirected_to '/issues/1'
  end

  def test_bulk_move_to_another_project
    @request.session[:user_id] = 2
    post :move, :ids => [1, 2], :new_project_id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    # Issues moved to project 2
    assert_equal 2, Issue.find(1).project_id
    assert_equal 2, Issue.find(2).project_id
    # No tracker change
    assert_equal 1, Issue.find(1).tracker_id
    assert_equal 2, Issue.find(2).tracker_id
  end
 
  def test_bulk_move_to_another_tracker
    @request.session[:user_id] = 2
    post :move, :ids => [1, 2], :new_tracker_id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_equal 2, Issue.find(1).tracker_id
    assert_equal 2, Issue.find(2).tracker_id
  end

  def test_bulk_copy_to_another_project
    @request.session[:user_id] = 2
    assert_difference 'Issue.count', 2 do
      assert_no_difference 'Project.find(1).issues.count' do
        post :move, :ids => [1, 2], :new_project_id => 2, :copy_options => {:copy => '1'}
      end
    end
    assert_redirected_to 'projects/ecookbook/issues'
  end

  context "#move via bulk copy" do
    should "allow not changing the issue's attributes" do
      @request.session[:user_id] = 2
      issue_before_move = Issue.find(1)
      assert_difference 'Issue.count', 1 do
        assert_no_difference 'Project.find(1).issues.count' do
          post :move, :ids => [1], :new_project_id => 2, :copy_options => {:copy => '1'}, :new_tracker_id => '', :assigned_to_id => '', :status_id => '', :start_date => '', :due_date => ''
        end
      end
      issue_after_move = Issue.first(:order => 'id desc', :conditions => {:project_id => 2})
      assert_equal issue_before_move.tracker_id, issue_after_move.tracker_id
      assert_equal issue_before_move.status_id, issue_after_move.status_id
      assert_equal issue_before_move.assigned_to_id, issue_after_move.assigned_to_id
    end
    
    should "allow changing the issue's attributes" do
      @request.session[:user_id] = 2
      assert_difference 'Issue.count', 2 do
        assert_no_difference 'Project.find(1).issues.count' do
          post :move, :ids => [1, 2], :new_project_id => 2, :copy_options => {:copy => '1'}, :new_tracker_id => '', :assigned_to_id => 4, :status_id => 3, :start_date => '2009-12-01', :due_date => '2009-12-31'
        end
      end

      copied_issues = Issue.all(:limit => 2, :order => 'id desc', :conditions => {:project_id => 2})
      assert_equal 2, copied_issues.size
      copied_issues.each do |issue|
        assert_equal 2, issue.project_id, "Project is incorrect"
        assert_equal 4, issue.assigned_to_id, "Assigned to is incorrect"
        assert_equal 3, issue.status_id, "Status is incorrect"
        assert_equal '2009-12-01', issue.start_date.to_s, "Start date is incorrect"
        assert_equal '2009-12-31', issue.due_date.to_s, "Due date is incorrect"
      end
    end
  end
  
  def test_copy_to_another_project_should_follow_when_needed
    @request.session[:user_id] = 2
    post :move, :ids => [1], :new_project_id => 2, :copy_options => {:copy => '1'}, :follow => '1'
    issue = Issue.first(:order => 'id DESC')
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue
  end
  
  def test_context_menu_one_issue
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => '/issues/1/edit',
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Closed',
                            :attributes => { :href => '/issues/1/edit?issue%5Bstatus_id%5D=5',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Immediate',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;priority_id=8',
                                             :class => '' }
    # Versions
    assert_tag :tag => 'a', :content => '2.0',
                            :attributes => { :href => '/issues/bulk_edit?fixed_version_id=3&amp;ids%5B%5D=1',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'eCookbook Subproject 1 - 2.0',
                            :attributes => { :href => '/issues/bulk_edit?fixed_version_id=4&amp;ids%5B%5D=1',
                                             :class => '' }

    assert_tag :tag => 'a', :content => 'Dave Lopper',
                            :attributes => { :href => '/issues/bulk_edit?assigned_to_id=3&amp;ids%5B%5D=1',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Duplicate',
                            :attributes => { :href => '/projects/ecookbook/issues/1/copy',
                                             :class => 'icon-duplicate' }
    assert_tag :tag => 'a', :content => 'Copy',
                            :attributes => { :href => '/issues/move?copy_options%5Bcopy%5D=t&amp;ids%5B%5D=1',
                                             :class => 'icon-copy' }
    assert_tag :tag => 'a', :content => 'Move',
                            :attributes => { :href => '/issues/move?ids%5B%5D=1',
                                             :class => 'icon-move' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '/issues/destroy?ids%5B%5D=1',
                                             :class => 'icon-del' }
  end

  test 'context_menu with a parent issue' do
    @request.session[:user_id] = 2
    @issue = Issue.generate_for_project!(Project.find(1), :subject => 'test')
    @issue.move_to_child_of Issue.find(1)

    get :context_menu, :ids => [1]

    assert_response :success
    assert_template 'context_menu'
    assert_select 'a[class*=disabled]', :text => /0%/
  end

  def test_context_menu_one_issue_by_anonymous
    get :context_menu, :ids => [1]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '#',
                                             :class => 'icon-del disabled' }
  end
  
  def test_context_menu_multiple_issues_of_same_project
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1, 2]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Immediate',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;ids%5B%5D=2&amp;priority_id=8',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Dave Lopper',
                            :attributes => { :href => '/issues/bulk_edit?assigned_to_id=3&amp;ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Copy',
                            :attributes => { :href => '/issues/move?copy_options%5Bcopy%5D=t&amp;ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-copy' }
    assert_tag :tag => 'a', :content => 'Move',
                            :attributes => { :href => '/issues/move?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-move' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '/issues/destroy?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-del' }
  end

  test 'context_menu with multiple issues and a parent issue' do
    @request.session[:user_id] = 2
    @issue = Issue.generate_for_project!(Project.find(1), :subject => 'test')
    @issue.move_to_child_of Issue.find(1)

    get :context_menu, :ids => [1,2]

    assert_response :success
    assert_template 'context_menu'
    assert_select 'a[class*=disabled]', :text => /0%/
  end

  def test_context_menu_multiple_issues_of_different_project
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1, 2, 4]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '#',
                                             :class => 'icon-del disabled' }
  end
  
  def test_destroy_routing
    assert_recognizes( #TODO: use DELETE on issue URI (need to change forms)
      {:controller => 'issues', :action => 'destroy', :id => '1'},
      {:method => :post, :path => '/issues/1/destroy'}
    )
  end
  
  def test_destroy_issue_with_no_time_entries
    assert_nil TimeEntry.find_by_issue_id(2)
    @request.session[:user_id] = 2
    post :destroy, :id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Issue.find_by_id(2)
  end

  def test_destroy_issues_with_time_entries
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3]
    assert_response :success
    assert_template 'destroy'
    assert_not_nil assigns(:hours)
    assert Issue.find_by_id(1) && Issue.find_by_id(3)
  end

  def test_destroy_issues_and_destroy_time_entries
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'destroy'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find_by_id([1, 2])
  end

  def test_destroy_issues_and_assign_time_entries_to_project
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'nullify'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find(1).issue_id
    assert_nil TimeEntry.find(2).issue_id
  end
  
  def test_destroy_issues_and_reassign_time_entries_to_another_issue
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'reassign', :reassign_to_id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_equal 2, TimeEntry.find(1).issue_id
    assert_equal 2, TimeEntry.find(2).issue_id
  end
  
  def test_default_search_scope
    get :index
    assert_tag :div, :attributes => {:id => 'quick-search'},
                     :child => {:tag => 'form',
                                :child => {:tag => 'input', :attributes => {:name => 'issues', :type => 'hidden', :value => '1'}}}
  end

  def test_new_child_issue
    child_issue_subject = "This is the test_new child issue"
    parent_issue = issues( :issues_root)
    @request.session[:user_id] = 2

    post( :new, :project_id => 1,
          :parent_issue => parent_issue,
          :issue => {:tracker_id => 3,
            :subject => child_issue_subject,
            :description => 'This is the description',
            :priority_id => 5,
            :parent_id => parent_issue.id.to_s,
            :estimated_hours => '',
            :custom_field_values => {'2' => 'Value for field 2'}})
    child = Issue.find_by_subject( child_issue_subject)

    assert_redirected_to "issues/#{child.id}"
    assert( child.parent == parent_issue,
            "New child has Issue id=#{child.parent} as parent, not id=#{parent_issue}")
  end

  def test_edit_issue_set_parent
    parent_issue = issues( :issues_root)
    moving_issue = issues( :issues_subchild003)
    @request.session[:user_id] = 2

    post( :edit,
          :id => moving_issue.id,
          :project_id => 1,
          :parent_issue => parent_issue,
          :issue => {
            :parent_id => parent_issue.id
          })
    assert_redirected_to :action => 'show', :id => moving_issue.id
    assert moving_issue.reload.parent == parent_issue
  end

  def test_move_child_to_root
    parent = issues( :issues_root)
    child = issues( :issues_child001)

    post( :edit,
          :id => child.id,
          :project_id => 1,
          :issue => {
            :parent_id => "",
          })
    assert_redirected_to :controller => 'issues', :action => 'show', :id => child.id
    assert child.reload.root?
  end

  def test_add_subissue_should_redirect_to_action_new
    @request.session[:user_id] = 2
    get( :add_subissue, :project_id => 1,
         :issue => {
           :tracker_id      => 3,
           :priority_id     => 5,
           :subject         => "test_add_subissue",
           :description     => "test_add_subissue",
           :estimated_hours => '' },
         :parent_issue_id => 1)
    assert_redirected_to :controller => 'issues', :action => "new", :project_id => Project.find(1).to_param, :issue => {:parent_id => 1}
  end

  def test_add_subissue_with_invalid_parent_id_should_render_404
    @request.session[:user_id] = 2
    get( :add_subissue, :project_id => 1,
         :issue => {
           :tracker_id => 3,
           :subject => "test_add_subissue",
           :description => "test_add_subissue",
           :priority_id => 5,
           :estimated_hours => ''},
         :parent_issue_id => 'invalid_id')
    assert_template 'common/404', :status => 404
  end

  def test_add_subissue_with_a_private_parent_issue
    @request.session[:user_id] = 3 # can't access Project 5
    get( :add_subissue, :project_id => 5,
         :issue => {
           :tracker_id      => 3,
           :priority_id     => 5,
           :subject         => "test_add_private_subissue",
           :description     => "test_add_private_subissue",
           :estimated_hours => '' },
         :parent_issue_id => 6)
    assert_template 'common/404', :status => 404
  end

  def test_index_view_option_always_show_parents
    @private_issue = Issue.find(4)
    @child_issue = Issue.find(15)
    @child_issue.move_to_child_of(@private_issue)

    @request.session[:user_id] = 3
    get( :index,
         :project_id => 1,
         :set_filter => 1,
         :view_options => { :show_parents => "show_always"})
    assert_response :success

    assert_select 'table.issues' do
      assert_select 'span.issue-subject-in-tree.issue-level-1', /child001/
      assert_select 'span.issue-subject-in-tree.issue-level-2', /subchild001/
      assert_select 'span', /root/

      # Hidden issue on a private project
      assert_select 'tr#issue-4', :count => 0
      assert_select 'td.subject', :text => /Issue on project 2/, :count => 0
      assert_select 'tr.private-issue .issue-subject', /Private/
    end
  end

  def test_index_view_option_organize_by_parent
    @private_issue = Issue.find(4)
    @child_issue = Issue.find(15)
    @child_issue.move_to_child_of(@private_issue)

    @request.session[:user_id] = 3
    get( :index,
         :project_id => 1,
         :set_filter => 1,
         :view_options => { :show_parents => "organize_by_parent"})
    assert_response :success

    assert_select 'table.issues' do
      assert_select '.issue-subject-in-tree.issue-level-1', /child001/
      assert_select '.issue-subject-in-tree.issue-level-1', /child002/
      assert_select '.issue-subject-in-tree.issue-level-2', /subchild001/
      assert_select '.issue-subject-in-tree.issue-level-2', /subchild002/
      assert_select 'tr.private-issue .issue-subject', /Private/
    end
  end

  context "#auto_complete_for_issue_parent without authorization" do
    setup do
      @request.session[:user_id] = 3
      get :auto_complete_for_issue_parent, :project_id => 2
    end

    should_respond_with 403
  end

  context "#auto_complete_for_issue_parent with authorization" do
    setup do
      @request.session[:user_id] = 3
    end

    context "with a missing phrase" do
      setup do
        get :auto_complete_for_issue_parent, :project_id => 1
      end

      should_respond_with :success

      should "have an hidden content body" do
        assert_select 'li[style*=?]', /display:none/
      end
    end

    context "with an issue number for the project" do
      setup do
        get :auto_complete_for_issue_parent, :project_id => 1, :issue_parent => '3'
      end

      should_respond_with :success

      should "have the matching issue in the content body" do
        assert_select 'ul' do
          assert_select 'li#3', /#{Issue.find(3).subject}/
        end
      end
    end

    context "with it's own issue number" do
      setup do
        get :auto_complete_for_issue_parent, :id => '3', :project_id => 1, :issue_parent => '3'
      end

      should_respond_with :success

      should "not show it's own issue as a result" do
        assert_select 'ul' do
          assert_select 'li#3', :count => 0
        end
      end
    end

    context "with a cross project issue number" do
      setup do
        Setting.cross_project_issue_relations = '1'
        get :auto_complete_for_issue_parent, :project_id => 1, :issue_parent => '5'
      end

      should_respond_with :success

      should "have the matching issue in the content body" do
        assert_select 'ul' do
          assert_select 'li#5', /#{Issue.find(5).subject}/
        end
      end
    end

    context "searching by subject and description" do
      setup do
        get :auto_complete_for_issue_parent, :project_id => 1, :issue_parent => 'issue'
      end

      should_respond_with :success

      should "have the matching issues in the content body" do
        assert_select 'ul' do
          assert_select 'li', :count => 7
        end
      end

    end

    context "searching to unauthorized projects by issue id" do
      setup do
        get :auto_complete_for_issue_parent, :project_id => 1, :issue_parent => '4'
      end

      should_respond_with :success

      should "not contain the unauthorized issues" do
        assert_select 'ul' do
          assert_select 'li#4', :count => 0
        end
      end

    end

    context "searching to unauthorized projects by subject and description" do
      setup do
        get :auto_complete_for_issue_parent, :project_id => 1, :issue_parent => 'issue on project 2'
      end

      should_respond_with :success

      should "not contain the unauthorized issues" do
        assert_select 'ul' do
          assert_select 'li', :count => 7
          assert_select 'li', :count => 0, :text => /issue on project 2/
        end
      end

    end

    should "limit results to 10 records" do
      Setting.cross_project_issue_relations = '1'
      get :auto_complete_for_issue_parent, :project_id => 1, :issue_parent => 'e'

      assert_response :success
      assert_select 'ul' do
        assert_select 'li', :count => 10
      end
    end


  end
end
