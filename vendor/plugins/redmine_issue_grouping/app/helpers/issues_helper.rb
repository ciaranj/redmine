module IssuesHelper
  def group_header(group)
    return "(none)" if group.blank?
    group.respond_to?(:subject) ? "#{link_to_issue(group)}: #{group.subject}" : group.to_s
  end
end