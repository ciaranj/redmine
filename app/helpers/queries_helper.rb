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

module QueriesHelper
  
  def operators_for_select(filter_type)
    Query.operators_by_filter_type[filter_type].collect {|o| [l(Query.operators[o]), o]}
  end
  
  def column_header(column)
    column.sortable ? sort_header_tag(column.name.to_s, :caption => column.caption,
                                                        :default_order => column.default_order) : 
                      content_tag('th', column.caption)
  end
  
  def column_content(column, issue, query = nil)
    value = column.value(issue)
    
    case value.class.name
    when 'String'
      if column.name == :subject
        subject_in_tree( issue, issue.subject, query)
      else
        h(value)
      end
    when 'Time'
      format_time(value)
    when 'Date'
      format_date(value)
    when 'Fixnum', 'Float'
      if column.name == :done_ratio
        progress_bar(value, :width => '80px')
      else
        value.to_s
      end
    when 'User'
      link_to_user value
    when 'Project'
      link_to(h(value), :controller => 'projects', :action => 'show', :id => value)
    when 'Version'
      link_to(h(value), :controller => 'versions', :action => 'show', :id => value)
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    else
      h(value)
    end
  end

  def subject_in_tree(issue, value, query)
    if query.view_options['show_parents'] == ViewOption::SHOW_PARENTS[:never]
      content_tag('div', subject_text(issue, value), :class=>'issue-subject')
    else
      css_style = "margin-left: #{issue.level}em;" # Used to indent
      content_tag('span',
                  content_tag('div',
                              subject_text(issue, value),
                              :class=>'issue-subject',
                              :style => css_style),
                  :class => issue.level > 0 ? "issue-subject-in-tree issue-level-#{issue.level}" : '',
                  :style => css_style)
    end
  end
  
  def subject_text(issue, value)
    if issue.visible?
      subject_text = link_to(h(value), :controller => 'issues', :action => 'show', :id => issue)
      h((@project.nil? || @project != issue.project) ? "#{issue.project.name} - " : '') + subject_text
    else
      h(value)
    end
  end

  def issue_content(issue, query, options = { })
    row_classes = ['issue','hascontextmenu', issue.css_classes, cycle('odd', 'even')]
    row_classes << 'issue-unfiltered' if options[:unfiltered]
    row_classes << 'issue-emphasis' if options[:emphasis]

    inner_content = returning '' do |content|
      content << content_tag(:td, check_box_tag("ids[]", issue.id, false, :id => nil), :class => 'checkbox')
      content << content_tag(:td, link_to(issue.id, :controller => 'issues', :action => 'show', :id => issue))

      query.columns.each do |column|
        content << content_tag( 'td', column_content(column, issue, query), :class => column.name)
      end
    end
    
    content_tag(:tr,
                inner_content,
                :id => "issue-#{issue.id}",
                :class => row_classes.join(' '))
  end

  def private_issue_content(issue, query, options = { })
    row_classes = ['issue', 'private-issue',cycle('odd', 'even')]
    row_classes << 'issue-unfiltered' if options[:unfiltered]
    row_classes << 'issue-emphasis' if options[:emphasis]

    inner_content = returning '' do |content|
      content << content_tag(:td, check_box_tag("ids[]", '', false, :id => nil), :class => 'checkbox')
      content << content_tag(:td, l(:text_private))

      query.columns.each do |column|
        if column.name == :subject
          # Need to indent
          content << content_tag('td', subject_in_tree(issue, l(:text_private), query), :class => column.name)
        else
          content << content_tag( 'td', l(:text_private), :class => column.name)
        end
      end
    end
    
    content_tag(:tr,
                inner_content,
                :id => "",
                :class => row_classes.join(' '))
    
  end

  def issues_family_content( parent, issues_to_show, query, emphasis_issues)
    html = ""
    if parent.visible?
      html << issue_content( parent, query, :unfiltered => !( issues_to_show.include? parent),
                             :emphasis => ( emphasis_issues ? emphasis_issues.include?( parent) : false))
    else
      html << private_issue_content( parent, query, :unfiltered => !( issues_to_show.include? parent),
                                     :emphasis => ( emphasis_issues ? emphasis_issues.include?( parent) : false))
    end
    unless  parent.children.empty?
      parent.children.each do |child|
        if issues_to_show.include?( child) || issues_to_show.detect { |i| i.ancestors.include? child }
          html << issues_family_content( child, issues_to_show, query, emphasis_issues)
        end
      end
    end
    html
  end

end
