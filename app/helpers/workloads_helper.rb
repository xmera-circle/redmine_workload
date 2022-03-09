# frozen_string_literal: true

module WorkloadsHelper
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
    render partial: 'redmine_workload/action_links'
  end
end
