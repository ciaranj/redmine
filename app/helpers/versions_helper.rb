# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

module VersionsHelper

  STATUS_BY_CRITERIAS = %w(category tracker priority author assigned_to)
  
  def render_issue_status_by(version, criteria)
    criteria ||= 'category'
    raise 'Unknown criteria' unless STATUS_BY_CRITERIAS.include?(criteria)
    
    h = Hash.new {|k,v| k[v] = [0, 0]}
    begin
      # Total issue count
      Issue.count(:group => criteria,
                  :conditions => ["#{Issue.table_name}.fixed_version_id = ?", version.id]).each {|c,s| h[c][0] = s}
      # Open issues count
      Issue.count(:group => criteria,
                  :include => :status,
                  :conditions => ["#{Issue.table_name}.fixed_version_id = ? AND #{IssueStatus.table_name}.is_closed = ?", version.id, false]).each {|c,s| h[c][1] = s}
    rescue ActiveRecord::RecordNotFound
    # When grouping by an association, Rails throws this exception if there's no result (bug)
    end
    counts = h.keys.compact.sort.collect {|k| {:group => k, :total => h[k][0], :open => h[k][1], :closed => (h[k][0] - h[k][1])}}
    max = counts.collect {|c| c[:total]}.max
    
    render :partial => 'issue_counts', :locals => {:version => version, :criteria => criteria, :counts => counts, :max => max}
  end
  
  def status_by_options_for_select(value)
    options_for_select(STATUS_BY_CRITERIAS.collect {|criteria| [l("field_#{criteria}".to_sym), criteria]}, value)
  end

  def render_list_of_related_issues( issues, version, current_level = 0)
    issues_on_current_level = issues.select { |i| i.level == current_level }
    issues -= issues_on_current_level
    content_tag( 'ul') do
      html = ''
      issues_on_current_level.each do |issue|
        opts_for_issue_li = { }
        if !issue.fixed_version or issue.fixed_version != version
          opts_for_issue_li[:class] = 'issue-unfiltered'
        end
        html << content_tag( 'li', opts_for_issue_li) do
          opts = { }
          if issue.done_ratio == 100
            opts[:style] = 'font-weight: bold'
          end
          link_to_issue(issue, opts)
        end
        children_to_print = issues & issue.children
        children_to_print += issues.select { |i| i.level >= current_level + 2}
        unless children_to_print.empty?
          html << render_list_of_related_issues( children_to_print, version, current_level + 1)
        end
      end
      html
    end
  end

end
