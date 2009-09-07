# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class ProjectTest < Test::Unit::TestCase
  fixtures :projects, :enabled_modules, 
           :issues, :issue_statuses, :journals, :journal_details,
           :users, :members, :member_roles, :roles, :projects_trackers, :trackers, :boards,
           :queries, :versions

  def setup
    @ecookbook = Project.find(1)
    @ecookbook_sub1 = Project.find(3)
  end
  
  def test_truth
    assert_kind_of Project, @ecookbook
    assert_equal "eCookbook", @ecookbook.name
  end
  
  def test_update
    assert_equal "eCookbook", @ecookbook.name
    @ecookbook.name = "eCook"
    assert @ecookbook.save, @ecookbook.errors.full_messages.join("; ")
    @ecookbook.reload
    assert_equal "eCook", @ecookbook.name
  end
  
  def test_validate
    @ecookbook.name = ""
    assert !@ecookbook.save
    assert_equal 1, @ecookbook.errors.count
    assert_equal I18n.translate('activerecord.errors.messages.blank'), @ecookbook.errors.on(:name)
  end
  
  def test_validate_identifier
    to_test = {"abc" => true,
               "ab12" => true,
               "ab-12" => true,
               "12" => false,
               "new" => false}
               
    to_test.each do |identifier, valid|
      p = Project.new
      p.identifier = identifier
      p.valid?
      assert_equal valid, p.errors.on('identifier').nil?
    end
  end
  
  def test_archive
    user = @ecookbook.members.first.user
    @ecookbook.archive
    @ecookbook.reload
    
    assert !@ecookbook.active?
    assert !user.projects.include?(@ecookbook)
    # Subproject are also archived
    assert !@ecookbook.children.empty?
    assert @ecookbook.descendants.active.empty?
  end
  
  def test_unarchive
    user = @ecookbook.members.first.user
    @ecookbook.archive
    # A subproject of an archived project can not be unarchived
    assert !@ecookbook_sub1.unarchive
    
    # Unarchive project
    assert @ecookbook.unarchive
    @ecookbook.reload
    assert @ecookbook.active?
    assert user.projects.include?(@ecookbook)
    # Subproject can now be unarchived
    @ecookbook_sub1.reload
    assert @ecookbook_sub1.unarchive
  end
  
  def test_destroy
    # 2 active members
    assert_equal 2, @ecookbook.members.size
    # and 1 is locked
    assert_equal 3, Member.find(:all, :conditions => ['project_id = ?', @ecookbook.id]).size
    # some boards
    assert @ecookbook.boards.any?
    
    @ecookbook.destroy
    # make sure that the project non longer exists
    assert_raise(ActiveRecord::RecordNotFound) { Project.find(@ecookbook.id) }
    # make sure related data was removed
    assert Member.find(:all, :conditions => ['project_id = ?', @ecookbook.id]).empty?
    assert Board.find(:all, :conditions => ['project_id = ?', @ecookbook.id]).empty?
  end
  
  def test_move_an_orphan_project_to_a_root_project
    sub = Project.find(2)
    sub.set_parent! @ecookbook
    assert_equal @ecookbook.id, sub.parent.id
    @ecookbook.reload
    assert_equal 4, @ecookbook.children.size
  end
  
  def test_move_an_orphan_project_to_a_subproject
    sub = Project.find(2)
    assert sub.set_parent!(@ecookbook_sub1)
  end
  
  def test_move_a_root_project_to_a_project
    sub = @ecookbook
    assert sub.set_parent!(Project.find(2))
  end
  
  def test_should_not_move_a_project_to_its_children
    sub = @ecookbook
    assert !(sub.set_parent!(Project.find(3)))
  end
  
  def test_set_parent_should_add_roots_in_alphabetical_order
    ProjectCustomField.delete_all
    Project.delete_all
    Project.create!(:name => 'Project C', :identifier => 'project-c').set_parent!(nil)
    Project.create!(:name => 'Project B', :identifier => 'project-b').set_parent!(nil)
    Project.create!(:name => 'Project D', :identifier => 'project-d').set_parent!(nil)
    Project.create!(:name => 'Project A', :identifier => 'project-a').set_parent!(nil)
    
    assert_equal 4, Project.count
    assert_equal Project.all.sort_by(&:name), Project.all.sort_by(&:lft)
  end
  
  def test_set_parent_should_add_children_in_alphabetical_order
    ProjectCustomField.delete_all
    parent = Project.create!(:name => 'Parent', :identifier => 'parent')
    Project.create!(:name => 'Project C', :identifier => 'project-c').set_parent!(parent)
    Project.create!(:name => 'Project B', :identifier => 'project-b').set_parent!(parent)
    Project.create!(:name => 'Project D', :identifier => 'project-d').set_parent!(parent)
    Project.create!(:name => 'Project A', :identifier => 'project-a').set_parent!(parent)
    
    parent.reload
    assert_equal 4, parent.children.size
    assert_equal parent.children.sort_by(&:name), parent.children
  end

  def test_set_parent_should_update_issue_fixed_version_associations_when_a_fixed_version_is_moved_out_of_the_hierarchy
    # Parent issue with a hierarchy project's fixed version
    parent_issue = Issue.find(1)
    parent_issue.update_attribute(:fixed_version_id, 4)
    parent_issue.reload
    assert_equal 4, parent_issue.fixed_version_id

    # Should keep fixed versions for the issues
    issue_with_local_fixed_version = Issue.find(5)
    issue_with_local_fixed_version.update_attribute(:fixed_version_id, 4)
    issue_with_local_fixed_version.reload
    assert_equal 4, issue_with_local_fixed_version.fixed_version_id

    # Local issue with hierarchy fixed_version
    issue_with_hierarchy_fixed_version = Issue.find(11)
    issue_with_hierarchy_fixed_version.update_attribute(:fixed_version_id, 6)
    issue_with_hierarchy_fixed_version.reload
    assert_equal 6, issue_with_hierarchy_fixed_version.fixed_version_id
    
    # Move project out of the issue's hierarchy
    moved_project = Project.find(3)
    moved_project.set_parent!(Project.find(2))
    parent_issue.reload
    issue_with_local_fixed_version.reload
    issue_with_hierarchy_fixed_version.reload
    
    assert_equal 4, issue_with_local_fixed_version.fixed_version_id, "Fixed version was not keep on an issue local to the moved project"
    assert_equal nil, issue_with_hierarchy_fixed_version.fixed_version_id, "Fixed version is still set after moving the Project out of the hierarchy where the version is defined in"
    assert_equal nil, parent_issue.fixed_version_id, "Fixed version is still set after moving the Version out of the hierarchy for the issue."
  end
  
  def test_rebuild_should_sort_children_alphabetically
    ProjectCustomField.delete_all
    parent = Project.create!(:name => 'Parent', :identifier => 'parent')
    Project.create!(:name => 'Project C', :identifier => 'project-c').move_to_child_of(parent)
    Project.create!(:name => 'Project B', :identifier => 'project-b').move_to_child_of(parent)
    Project.create!(:name => 'Project D', :identifier => 'project-d').move_to_child_of(parent)
    Project.create!(:name => 'Project A', :identifier => 'project-a').move_to_child_of(parent)
    
    Project.update_all("lft = NULL, rgt = NULL")
    Project.rebuild!
    
    parent.reload
    assert_equal 4, parent.children.size
    assert_equal parent.children.sort_by(&:name), parent.children
  end
  
  def test_parent
    p = Project.find(6).parent
    assert p.is_a?(Project)
    assert_equal 5, p.id
  end
  
  def test_ancestors
    a = Project.find(6).ancestors
    assert a.first.is_a?(Project)
    assert_equal [1, 5], a.collect(&:id)
  end
  
  def test_root
    r = Project.find(6).root
    assert r.is_a?(Project)
    assert_equal 1, r.id
  end
  
  def test_children
    c = Project.find(1).children
    assert c.first.is_a?(Project)
    assert_equal [5, 3, 4], c.collect(&:id)
  end
  
  def test_descendants
    d = Project.find(1).descendants
    assert d.first.is_a?(Project)
    assert_equal [5, 6, 3, 4], d.collect(&:id)
  end
  
  def test_users_by_role
    users_by_role = Project.find(1).users_by_role
    assert_kind_of Hash, users_by_role
    role = Role.find(1)
    assert_kind_of Array, users_by_role[role]
    assert users_by_role[role].include?(User.find(2))
  end
  
  def test_rolled_up_trackers
    parent = Project.find(1)
    parent.trackers = Tracker.find([1,2])
    child = parent.children.find(3)
  
    assert_equal [1, 2], parent.tracker_ids
    assert_equal [2, 3], child.trackers.collect(&:id)
    
    assert_kind_of Tracker, parent.rolled_up_trackers.first
    assert_equal Tracker.find(1), parent.rolled_up_trackers.first
    
    assert_equal [1, 2, 3], parent.rolled_up_trackers.collect(&:id)
    assert_equal [2, 3], child.rolled_up_trackers.collect(&:id)
  end
  
  def test_rolled_up_trackers_should_ignore_archived_subprojects
    parent = Project.find(1)
    parent.trackers = Tracker.find([1,2])
    child = parent.children.find(3)
    child.trackers = Tracker.find([1,3])
    parent.children.each(&:archive)
    
    assert_equal [1,2], parent.rolled_up_trackers.collect(&:id)
  end

  def test_shared_versions
    parent = Project.find(1)
    child = parent.children.find(3)
    private_child = parent.children.find(5)
    
    assert_equal [1,2,3], parent.version_ids.sort
    assert_equal [4], child.version_ids
    assert_equal [6], private_child.version_ids
    assert_equal [7], Version.find_all_by_shared('system').collect(&:id)

    assert_equal 6, parent.shared_versions.size
    parent.shared_versions.each do |version|
      assert_kind_of Version, version
    end

    assert_equal [1,2,3,4,6,7], parent.shared_versions.collect(&:id).sort
  end

  def test_shared_versions_should_ignore_archived_subprojects
    parent = Project.find(1)
    child = parent.children.find(3)
    child.archive
    parent.reload
    
    assert_equal [1,2,3], parent.version_ids.sort
    assert_equal [4], child.version_ids
    assert !parent.shared_versions.collect(&:id).include?(4)
  end

  def test_shared_versions_visible_to_user
    user = User.find(3)
    parent = Project.find(1)
    child = parent.children.find(5)
    
    assert_equal [1,2,3], parent.version_ids.sort
    assert_equal [6], child.version_ids

    versions = parent.shared_versions_visible_to_user(user)
    
    assert_equal 4, versions.size
    versions.each do |version|
      assert_kind_of Version, version
    end

    assert !versions.collect(&:id).include?(6)
  end

  def test_next_identifier
    ProjectCustomField.delete_all
    Project.create!(:name => 'last', :identifier => 'p2008040')
    assert_equal 'p2008041', Project.next_identifier
  end
  
  def test_next_identifier_first_project
    Project.delete_all
    assert_nil Project.next_identifier
  end
  

  def test_enabled_module_names_should_not_recreate_enabled_modules
    project = Project.find(1)
    # Remove one module
    modules = project.enabled_modules.slice(0..-2)
    assert modules.any?
    assert_difference 'EnabledModule.count', -1 do
      project.enabled_module_names = modules.collect(&:name)
    end
    project.reload
    # Ids should be preserved
    assert_equal project.enabled_module_ids.sort, modules.collect(&:id).sort
  end

  def test_copy_from_existing_project
    source_project = Project.find(1)
    copied_project = Project.copy_from(1)

    assert copied_project
    # Cleared attributes
    assert copied_project.id.blank?
    assert copied_project.name.blank?
    assert copied_project.identifier.blank?
    
    # Duplicated attributes
    assert_equal source_project.description, copied_project.description
    assert_equal source_project.enabled_modules, copied_project.enabled_modules
    assert_equal source_project.trackers, copied_project.trackers

    # Default attributes
    assert_equal 1, copied_project.status
  end
  
  # Context: Project#copy
  def test_copy_should_copy_issues
    # Setup
    ProjectCustomField.destroy_all # Custom values are a mess to isolate in tests
    source_project = Project.find(2)
    Project.destroy_all :identifier => "copy-test"
    project = Project.new(:name => 'Copy Test', :identifier => 'copy-test')
    project.trackers = source_project.trackers
    assert project.valid?
    
    assert project.issues.empty?
    assert project.copy(source_project)

    # Tests
    assert_equal source_project.issues.size, project.issues.size
    project.issues.each do |issue|
      assert issue.valid?
      assert ! issue.assigned_to.blank?
      assert_equal project, issue.project
    end
  end
  
  def test_copy_should_copy_members
    # Setup
    ProjectCustomField.destroy_all # Custom values are a mess to isolate in tests
    source_project = Project.find(2)
    project = Project.new(:name => 'Copy Test', :identifier => 'copy-test')
    project.trackers = source_project.trackers
    project.enabled_modules = source_project.enabled_modules
    assert project.valid?

    assert project.members.empty?
    assert project.copy(source_project)

    # Tests
    assert_equal source_project.members.size, project.members.size
    project.members.each do |member|
      assert member
      assert_equal project, member.project
    end
  end

  def test_copy_should_copy_project_level_queries
    # Setup
    ProjectCustomField.destroy_all # Custom values are a mess to isolate in tests
    source_project = Project.find(2)
    project = Project.new(:name => 'Copy Test', :identifier => 'copy-test')
    project.trackers = source_project.trackers
    project.enabled_modules = source_project.enabled_modules
    assert project.valid?

    assert project.queries.empty?
    assert project.copy(source_project)

    # Tests
    assert_equal source_project.queries.size, project.queries.size
    project.queries.each do |query|
      assert query
      assert_equal project, query.project
    end
  end

  def test_systemwide
    assert !Version.find(1).systemwide? # not shared
    assert !Version.find(4).systemwide? # hierarchy
    assert Version.find(7).systemwide? # system
  end

end
