# frozen_string_literal: true

require 'redmine'
require File.expand_path('lib/redmine_workload', __dir__)

Redmine::Plugin.register :redmine_workload do
  name 'Redmine workload plugin'
  author 'Jost Baron, Liane Hampe, xmera Solutions GmbH'
  description 'This is a plugin for Redmine, originally developed by Rafael Calleja. It ' \
              'displays the estimated number of hours users and groups have to work to finish ' \
              'all their assigned issus on time.'
  version '4.0.0'
  url 'https://github.com/xmera-circle/redmine_workload'
  requires_redmine version_or_higher: '6.1'

  menu :top_menu,
       :WorkLoad,
       { controller: 'workloads', action: 'index' },
       caption: :workload_title,
       if: proc {
             User.current.logged? && User.current.allowed_to?({ controller: :workloads, action: :index },
                                                              nil, global: true)
           }

  settings partial: 'settings/workload_settings',
           default: {
             'threshold_lowload_min' => 0.1,
             'threshold_normalload_min' => 7,
             'threshold_highload_min' => 8.5,
             'workload_of_parent_issues' => ''
           }

  permission :view_all_workloads, workloads: :index
  permission :view_own_workloads, workloads: :index
  permission :view_own_group_workloads, workloads: :index
  permission :edit_national_holiday, wl_national_holiday: %i[create update destroy]
  permission :edit_user_vacations,   wl_user_vacations: %i[create update destroy]
  permission :edit_user_data,        wl_user_datas: :update
end

class RedmineToolbarHookListener < Redmine::Hook::ViewListener
  # Controllers whose views need the plugin's assets.
  WORKLOAD_CONTROLLERS = %w[
    workloads
    wl_user_datas
    wl_user_vacations
    wl_national_holiday
  ].freeze

  def view_layouts_base_html_head(context = {})
    return '' unless workload_page?(context)

    javascript_include_tag('slides', plugin: :redmine_workload) +
      stylesheet_link_tag('style', plugin: :redmine_workload)
  end

  private

  def workload_page?(context)
    controller = context[:controller]
    return false unless controller

    WORKLOAD_CONTROLLERS.include?(controller.params[:controller].to_s)
  end
end
