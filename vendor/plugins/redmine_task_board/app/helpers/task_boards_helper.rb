module TaskBoardsHelper
  def status_classes_for(issue, user)
    statuses = issue.new_statuses_allowed_to(user)-[issue.status]
    status_class_names = statuses.map {|status| status.to_s.gsub(" ",'').underscore }
    status_class_names.join(' ')
  end
end
