require 'redmine'
require_dependency 'dateTools'
require_dependency 'list_user'
require_dependency 'calculos_tareas'

Redmine::Plugin.register :redmine_workload do
  name 'Redmine Workload plugin'
  author 'Yann Bogdanovic, Jost Baron'
  description 'This is a plugin for Redmine, originally developed by Dnoise Rafael Calleja'
  version '0.2.0'
  url 'https://github.com/JostBaron/Redmine-Workload-Dnoise'
  author_url 'http://www.d-noise.net/'

  menu :top_menu, :WorkLoad, { :controller => 'work_load', :action => 'show' }, :caption => :workload_title,
    :if =>  Proc.new { User.current.logged? }

end

class RedmineToolbarHookListener < Redmine::Hook::ViewListener
   def view_layouts_base_html_head(context)
     stylesheet_link_tag('style', :plugin => :redmine_workload )
   end
end
