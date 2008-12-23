module TaskBoardsHelper
  def status_classes_for(issue, user)
    statuses = issue.new_statuses_allowed_to(user)-[issue.status]
    status_class_names = statuses.map {|status| status.class_name }
    status_class_names.join(' ')
  end

  def task_board_drop_receiving_element(dom_id, status)
    drop_receiving_element(dom_id,
      :accept => status.class_name,
      :hoverclass => 'hovered',
      :url => {:controller => 'task_boards', :action => 'update_issue_status'},
      :with => "'id=' + (element.id.split('_').last()) + '&status_id=#{status.id}'")
  end
end