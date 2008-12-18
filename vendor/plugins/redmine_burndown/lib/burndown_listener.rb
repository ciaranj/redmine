class BurndownListener < Redmine::Hook::ViewListener
  def view_versions_show_bottom(context={})
    "<hr/>" + link_to("Burndown Chart", show_burndown_path(:id => context[:version]))  
  end
  
  def view_layouts_base_html_head(context={})
    stylesheet_link_tag('burndowns', :plugin => 'redmine_burndown')
  end
end