# frozen_string_literal: true

module WorkLoadHelper
  ##
  # Unused method in this plugin. Moreover there seems to be no 'allowed_users'
  # setting.
  #
  # @deprecated Will be removed from Redmine Workload 2.0.0
  #
  def workload_admin?
    allowed_users = Setting.plugin_redmine_workload['allowed_users']
    allowed_users.present? && allowed_users.include?(User.current.id.to_s)
  end

  deprecate :workload_admin?, deprecator: RedmineWorkload.major_release_deprecator

  def render_action_links
    links = []

    links << link_to(l(:workload_title), controller: 'work_load', action: 'show')

    # if is_workload_admin
    links << link_to(l(:workload_holiday_title), controller: 'wl_national_holiday', action: 'index') if workload_admin?
    # end

    # if User.current.allowed_to_globally?(:edit_user_data)
    links << link_to(l(:workload_user_data_title), controller: 'wl_user_datas', action: 'show')
    # end

    # if User.current.allowed_to_globally?(:edit_user_vacations)
    links << link_to(l(:workload_user_vacation_menu), controller: 'wl_user_vacations', action: 'index')
    # end

    links.join(' | ').html_safe
  end
end
