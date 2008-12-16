class TaskBoardListener < Redmine::Hook::ViewListener
  def view_versions_show_bottom(context={})
    "<hr/>" + link_to("Task Board", show_task_board_path(:id => context[:version]))
  end
end
