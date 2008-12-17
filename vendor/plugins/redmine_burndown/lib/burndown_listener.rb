class BurndownListener < Redmine::Hook::ViewListener
  def view_versions_show_bottom(context={})
    "<hr/>" + link_to("Burndown Chart", show_burndown_path(:id => context[:version]))  
  end
end
