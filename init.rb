require 'redmine'
require_dependency 'dateTools'
require_dependency 'list_user'
require_dependency 'calculos_tareas'

Redmine::Plugin.register :redmine_workload do
  name 'Redmine Workload plugin'
  author 'Yann Bogdanovic'
  description 'This is a plugin for Redmine Workload originaly developped by Dnoise Rafael Calleja'
  version '0.1.0'
  url 'https://github.com/ianbogda/redmine_workload'
  author_url 'http://www.d-noise.net/'
  
  project_module :workload do
    permission :WorkLoad, {:work_load => [:index ] }, :public => true
  end

  menu :top_menu, :WorkLoad, { :controller => 'work_load', :action => 'show' }, :caption => :workload_title,
    :if =>  Proc.new { User.current.allowed_to?({ :controller => 'show'}, nil, :global:true) }

end

class RedmineToolbarHookListener < Redmine::Hook::ViewListener
   def view_layouts_base_html_head(context)
     stylesheet_link_tag('style', :plugin => :redmine_workload )
   end
end
