require 'redmine'
require_dependency 'dateTools'
require_dependency 'list_user'

Redmine::Plugin.register :redmine_workload do
  name 'Redmine Workload plugin'
  author 'Jost Baron'
  description 'This is a plugin for Redmine, originally developed by Rafael Calleja. It ' +
              'displays the estimated number of hours users have to perform for each day to finish ' +
              'all their assigned issus on time.'
  version '0.3.0'
  url 'https://github.com/JostBaron/redmine_workload'
  author_url 'http://netzkönig.de/'

  menu :top_menu, :WorkLoad, { :controller => 'work_load', :action => 'show' }, :caption => :workload_title,
    :if =>  Proc.new { User.current.logged? }

  settings :default => {'empty' => true}, :partial => 'settings/workload_settings'

  permission :view_project_workload, :work_load => :show

end

class RedmineToolbarHookListener < Redmine::Hook::ViewListener
   def view_layouts_base_html_head(context)
     stylesheet_link_tag('style', :plugin => :redmine_workload )
   end
end
