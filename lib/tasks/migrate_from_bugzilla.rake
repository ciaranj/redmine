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
#
# Bugzilla migration by Arjen Roodselaar, Lindix bv edited by Oliver Sigge
#
# Successfully tested with Bugzilla 2.20, Redmine devBuild, Rails 2.1
#
# Please note that the users in the Bugzilla database must have a forename and surename

desc 'Bugzilla migration script'

require 'active_record'
require 'iconv'
require 'pp'
require 'ftools'

namespace :redmine do
task :migrate_from_bugzilla => :environment do
  
    module BugzillaMigrate
   
      DEFAULT_STATUS = IssueStatus.default
      CLOSED_STATUS = IssueStatus.find :first, :conditions => { :is_closed => true }
      assigned_status = IssueStatus.find_by_position(2)
      resolved_status = IssueStatus.find_by_position(3)
      feedback_status = IssueStatus.find_by_position(4)
      
      #Create a verified status
      verified_status= IssueStatus.create :name=> 'Verified', :is_closed=> true
      
      STATUS_MAPPING = {
        "UNCONFIRMED" => DEFAULT_STATUS,
        "NEW" => DEFAULT_STATUS,
        "VERIFIED" => verified_status,
        "ASSIGNED" => assigned_status,
        "REOPENED" => assigned_status,
        "RESOLVED" => resolved_status,
        "CLOSED" => CLOSED_STATUS
      }
      # actually close resolved issues
      resolved_status.is_closed = true
      resolved_status.save
                        
      priorities = Enumeration.get_values('IPRI')
      PRIORITY_MAPPING = {
        "P1 - Immediate Fix" => priorities[5], # low
        "P2 - Fix In Release" => priorities[4], # normal
        "P3 - Like To Have" => priorities[3], # high
        "P4 - Desirable" => priorities[2], # urgent
        "{not set}" => priorities[1]  # immediate
      }
      DEFAULT_PRIORITY = PRIORITY_MAPPING["P2"]
    
      TRACKER_BUG = Tracker.find_by_position(1)
      TRACKER_FEATURE = Tracker.find_by_position(2)
      TRACKER_STORY = Tracker.find_by_name('Story')
      
      reporter_role = Role.find_by_position(5)
      developer_role = Role.find_by_position(4)
      manager_role = Role.find_by_position(3)
      DEFAULT_ROLE = developer_role
      
      CUSTOM_FIELD_TYPE_MAPPING = {
        0 => 'string', # String
        1 => 'int',    # Numeric
        2 => 'int',    # Float
        3 => 'list',   # Enumeration
        4 => 'string', # Email
        5 => 'bool',   # Checkbox
        6 => 'list',   # List
        7 => 'list',   # Multiselection list
        8 => 'date',   # Date
      }
                                   
      RELATION_TYPE_MAPPING = {
        0 => IssueRelation::TYPE_DUPLICATES, # duplicate of
        1 => IssueRelation::TYPE_RELATES,    # related to
        2 => IssueRelation::TYPE_RELATES,    # parent of
        3 => IssueRelation::TYPE_RELATES,    # child of
        4 => IssueRelation::TYPE_DUPLICATES  # has duplicate
      }
                               
      class BugzillaProfile < ActiveRecord::Base
        set_table_name :profiles
        set_primary_key :userid
        
        has_and_belongs_to_many :groups,
          :class_name => "BugzillaGroup",
          :join_table => :user_group_map,
          :foreign_key => :user_id,
          :association_foreign_key => :group_id
        
        def login
          login_name[0..29].gsub(/[^a-zA-Z0-9_\-@\.]/, '')
        end
        
        def email
          if login_name.match(/^.*@.*$/i)
            login_name
          else
            "#{login_name}@foo.bar"
          end
        end
        
        def firstname
          read_attribute(:realname).blank? ? login_name : read_attribute(:realname).split.first[0..29]
        end

        def lastname
          read_attribute(:realname).blank? ? login_name : read_attribute(:realname).split[1..-1].join(' ')[0..29]
        end
      end
      
      class BugzillaGroup < ActiveRecord::Base
        set_table_name :groups
        
        has_and_belongs_to_many :profiles,
          :class_name => "BugzillaProfile",
          :join_table => :user_group_map,
          :foreign_key => :group_id,
          :association_foreign_key => :user_id
      end
      
      class BugzillaProduct < ActiveRecord::Base
        set_table_name :products
        
        has_many :components, :class_name => "BugzillaComponent", :foreign_key => :product_id
        has_many :versions, :class_name => "BugzillaVersion", :foreign_key => :product_id
        has_many :targetmilestones, :class_name => "BugzillaMilestone", :foreign_key => :product_id
        has_many :bugs, :class_name => "BugzillaBug", :foreign_key => :product_id
      end
      
      class BugzillaComponent < ActiveRecord::Base
        set_table_name :components
      end
      
      class BugzillaVersion < ActiveRecord::Base
        set_table_name :versions
      end
      
      class BugzillaMilestone < ActiveRecord::Base
        set_table_name :milestones
      end
      
      class BugzillaAttachment < ActiveRecord::Base
        set_table_name :attachments
        belongs_to :bug, :class_name => "BugzillaBug", :foreign_key => :bug_id
        has_one :attachment_data, :class_name => "BugzillaAttachmentData"
      end
      
      class BugzillaAttachmentData < ActiveRecord::Base
        set_table_name :attach_data
        belongs_to :attachment, :class_name => "BugzillaAttachment", :foreign_key => :id
      end
      
      class BugzillaBug < ActiveRecord::Base
        set_table_name :bugs
        set_primary_key :bug_id
        
        belongs_to :product, :class_name => "BugzillaProduct", :foreign_key => :product_id
        has_many :descriptions, :class_name => "BugzillaDescription", :foreign_key => :bug_id
        has_many :attachments, :class_name => "BugzillaAttachment", :foreign_key => :bug_id
      end
      
      class BugzillaDescription < ActiveRecord::Base
        set_table_name :longdescs
        
        belongs_to :bug, :class_name => "BugzillaBug", :foreign_key => :bug_id
        
        def eql(desc)
          self.bug_when == desc.bug_when
        end
        
        def === desc
          self.eql(desc)
        end
        
        def self.inheritance_column
          "inh_type"
        end
        
        def text
          if self.thetext.blank?
            return nil
          else
            self.thetext
          end 
        end
      end
      
      def self.establish_connection(params)
        constants.each do |const|
          klass = const_get(const)
          next unless klass.respond_to? 'establish_connection'
          klass.establish_connection params
        end
      end
      
      def self.migrate
        
        # Profiles
        print "Migrating profiles\n"
        $stdout.flush
        User.delete_all "login <> 'admin'"
        users_map = {}
        users_migrated = 0
        BugzillaProfile.find(:all).each do |profile|
          user = User.new
          user.login = profile.login
          user.password = "bugzilla"
          user.firstname = profile.firstname
          user.lastname = profile.lastname
          user.mail = profile.email
          user.status = User::STATUS_LOCKED if !profile.disabledtext.empty?
          user.admin = true if profile.groups.include?(BugzillaGroup.find_by_name("admin"))
                
         next unless user.save
        	users_migrated += 1
        	users_map[profile.userid] = user
        	print '.'
        	$stdout.flush
        end
        
        
        # Products
        puts
        print "Migrating products"
        $stdout.flush
        
        Project.destroy_all
        projects_map = {}
        target_milestones_map = {}
        categories_map = {}
        BugzillaProduct.find(:all, :conditions => { :id=>9}).each do |product|
          project = Project.new
          project.name = product.name
          project.description = product.description
          project.identifier = product.name.downcase.gsub(/[0-9_\s\.]*/, '')[0..15]
          project.trackers[0] = TRACKER_BUG
#          puts "Name: #{product.name}; Identifier: #{project.identifier}\n"
          next unless project.save
          projects_map[product.id] = project
        	print "."
        	$stdout.flush

        	# Enable issue tracking
        	enabled_module = EnabledModule.new(
        	  :project => project,
        	  :name => 'issue_tracking'
        	)
        	enabled_module.save
          # Components
          product.components.each do |component|
            category = IssueCategory.new(:name => component.name[0,30])
            category.project = project
            category.assigned_to = users_map[component.initialowner]
            category.save
            categories_map[component.id] = category
          end
          # Add default user roles
        	1.upto(users_map.length) do |i|
            membership = Member.new(
              :user => users_map[i],
              :project => project,
              :role => DEFAULT_ROLE
            )
            membership.save
        	end
        	# Versions
        	product.targetmilestones.each do |bugzilla_version|
        	  unless ['---','4.0 Backlog','4.1 Backlog','ONGOING_DEV','Sometime'].include? bugzilla_version.value
        	    version= Version.new(:name => bugzilla_version.value)
        	    version.save
        	    project.versions << version 
        	    target_milestones_map[bugzilla_version.value]= version
        	  end
        	end
        	project.save
        end
        
        # Bugs
        puts "\n"
        print "Migrating bugs"
        Issue.destroy_all
        issues_map = {}
        skipped_bugs = []
        BugzillaBug.find(:all, :conditions => { :product_id=>9}, :order=>'bug_id asc').each do |bug|
          issue = Issue.new(
            :id => 2333,
            :project => projects_map[bug.product_id],
            :tracker => TRACKER_BUG,
            :subject => bug.short_desc,
            :description => bug.descriptions.first.text || bug.short_desc,
            :author => users_map[bug.reporter],
            :priority => PRIORITY_MAPPING[bug.priority] || DEFAULT_PRIORITY,
            :status => STATUS_MAPPING[bug.bug_status] || DEFAULT_STATUS,
            :start_date => bug.creation_ts,
            :created_on => bug.creation_ts,
            :updated_on => bug.delta_ts,
            :fixed_version => target_milestones_map[bug.target_milestone]
          )

          issue.category = categories_map[bug.component_id] unless bug.component_id.blank?                  
          issue.assigned_to = users_map[bug.assigned_to] unless bug.assigned_to.blank?  
          Issue.connection.execute("ALTER TABLE issues AUTO_INCREMENT = #{bug.bug_id}")        
          if issue.save
            print '.'
        	else
        	  issue.id = bug.bug_id
        	  skipped_bugs << issue
        	  print "!"
        	  next
        	end
        	$stdout.flush
  #      	print bug.attachments.length
          # notes
          bug.descriptions.each do |description|
            # the first comment is already added to the description field of the bug
            next if description === bug.descriptions.first
            journal = Journal.new(
              :journalized => issue,
              :user => users_map[description.who],
              :notes => description.text,
              :created_on => description.bug_when
            )
            if (journal.user.nil?)
             journal.user = User.find(:first)
            end
            next unless journal.save
          end
#          bug.attachments.each do |bugzilla_attachment|
#            attachment= Attachment.new( 
#              :container => bug,
#              :author => users_map[bugzilla_attachment.submitter_id]
#            )
#            temp_file= File.new('import_tmp_file','w')
#            attachment.file= temp_file
#            if attachment.save?
#              print '#'
#            else
#              print '~'
#            end
#          end
          $stdout.flush
        end

        # set a due-date on each sprint to be the date of the most recent updated_on value of the bug
        Version.find(:all).each do |version|
          last_issue= version.fixed_issues.find(:first, :order=>'created_on desc')
          first_issue= version.fixed_issues.find(:first, :order=>'created_on asc')
          version.effective_date= last_issue.created_on
          version.created_on= first_issue.created_on
          version.save(false)
        end
        puts
        
        puts
        puts "Profiles:       #{users_migrated}/#{BugzillaProfile.count}"
        puts "Products:       #{Project.count}/#{BugzillaProduct.count}"
        puts "Components:     #{IssueCategory.count}/#{BugzillaComponent.count}"
        puts "Bugs            #{Issue.count}/#{BugzillaBug.count}"
        puts
        
        if !skipped_bugs.empty?
          puts "The following bugs failed to import: "
          skipped_bugs.each do |issue|
            print "#{issue.id}, reason: "
            issue.errors.each{|error| print "#{error}"}
            puts
          end
        end
      end

      puts
      puts "WARNING: Your Redmine data will be deleted during this process."
      print "Are you sure you want to continue ? [y/N] "
      break unless STDIN.gets.match(/^y$/i)
      
      # Default Bugzilla database settings
      db_params = {:adapter => 'mysql', 
                   :database => 'bugs', 
                   :host => 'localhost',
                   #:port => 3308,
                   :socket => '/Applications/MAMP/tmp/mysql/mysql.sock',
                   :username => 'rails', 
                   :password => 'rails',
                   :encoding => 'utf8' }

      puts
      puts "Please enter settings for your Bugzilla database"  
      [:adapter, :host, :database, :username, :password].each do |param|
        print "#{param} [#{db_params[param]}]: "
        value = STDIN.gets.chomp!
        db_params[param] = value unless value.blank?
      end
      
      BugzillaMigrate.establish_connection db_params
      BugzillaMigrate.migrate
    end
    
end
end
