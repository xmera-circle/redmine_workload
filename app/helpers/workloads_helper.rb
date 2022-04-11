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

  ##
  # Determines the css class for hours in dependence of the workload level.
  #
  # @param [Float] The decimal number of hours.
  # @param [User] A user object.
  # @return [String] The css class for highlighting the hours in the workload table.
  #
  def load_class_for_hours(hours, user, user_data = nil)
    raise ArgumentError unless hours.respond_to?(:to_f)

    hours = hours.to_f
    lowload, normalload, highload = threshold_values(user, user_data)

    if hours < lowload
      'none'
    elsif hours < normalload
      'low'
    elsif hours < highload
      'normal'
    else
      'high'
    end
  end

  def threshold_values(user, user_data)
    default_lowload = Setting['plugin_redmine_workload']['threshold_lowload_min'].to_f
    default_normalload = Setting['plugin_redmine_workload']['threshold_normalload_min'].to_f
    default_highload = Setting['plugin_redmine_workload']['threshold_highload_min'].to_f

    workload = user_data || user

    lowload     = workload&.threshold_lowload_min || default_lowload
    normalload  = workload&.threshold_normalload_min || default_normalload
    highload    = workload&.threshold_highload_min || default_highload

    [lowload, normalload, highload]
  end

  def render_action_links
    render partial: 'redmine_workload/action_links'
  end
end
