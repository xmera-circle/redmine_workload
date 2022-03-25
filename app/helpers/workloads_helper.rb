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
  def load_class_for_hours(hours, user = nil)
    raise ArgumentError unless hours.respond_to?(:to_f)

    hours = hours.to_f

    # load defaults:
    lowLoad = Setting['plugin_redmine_workload']['threshold_lowload_min'].to_f
    normalLoad = Setting['plugin_redmine_workload']['threshold_normalload_min'].to_f
    highLoad = Setting['plugin_redmine_workload']['threshold_highload_min'].to_f

    unless user.nil?
      user_workload_data = WlUserData.find_by user_id: user.id
      unless user_workload_data.nil?
        lowLoad     = user_workload_data.threshold_lowload_min
        normalLoad  = user_workload_data.threshold_normalload_min
        highLoad    = user_workload_data.threshold_highload_min
      end
    end

    if hours < lowLoad
      'none'
    elsif hours < normalLoad
      'low'
    elsif hours < highLoad
      'normal'
    else
      'high'
    end
  end

  def render_action_links
    render partial: 'redmine_workload/action_links'
  end
end
