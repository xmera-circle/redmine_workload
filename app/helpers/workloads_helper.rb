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

  ##
  # Writes the css class for a group, user, and project combined.
  # @see css_group_class
  # @see css_user_class
  # @see css_project_class
  #
  def css_group_user_project_class(group_id, user_id, project_id)
    "#{css_group_class(group_id)} #{css_user_class(user_id)} #{css_project_class(project_id)}"
  end

  ##
  # Writes the css class for a project.
  # @param project_id [Integer] The project id.
  #
  def css_project_class(project_id)
    return unless project_id

    "project-#{project_id}"
  end

  ##
  # Writes the css class for a group and user combined.
  # @see css_group_class
  # @see css_user_class
  #
  def css_group_user_class(group_id, user_id)
    "#{css_group_class(group_id)} #{css_user_class(user_id)}"
  end

  ##
  # Writes the css class for a group.
  # @param group_id [Integer] The group id.
  #
  def css_group_class(group_id)
    return unless group_id

    "group-#{group_id}"
  end

  ##
  # Writes the css class for a user.
  # @param user_id [Integer] The user id.
  #
  def css_user_class(user_id)
    return unless user_id

    "user-#{user_id}"
  end

  ##
  # Determines the css class for hours in dependence of the workload level.
  #
  # @param [Float] The decimal number of hours.
  # @param [User] A user object.
  # @return [String] The css class for highlighting the hours in the workload table.
  #
  def load_class_for_hours(hours, user = nil)
    hours = hours.to_f
    lowload, normalload, highload = threshold_values(user)

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

  def threshold_values(user)
    settings = user_settings(user)
    [settings.threshold_lowload_min, settings.threshold_normalload_min, settings.threshold_highload_min]
  end

  def user_settings(user)
    return user if user.is_a?(GroupUserDummy)

    user&.wl_user_data || WlDefaultUserData.new
  end

  def groups?(groups)
    return false unless groups

    groups.selected.presence
  end

  def filter_type(groups)
    groups?(groups) ? 'groups' : 'users'
  end

  def workloads_to_csv(workload, params)
    prepare = WlCsvExportPreparer.new(data: workload, params: params)
    Redmine::Export::CSV.generate(encoding: params[:encoding]) do |csv|
      csv << prepare.header_fields
      prepare.group_workload.each do |level, data|
        csv << prepare.line(level, data)
      end
      prepare.user_workload.each do |level, data|
        csv << prepare.line(level, data)
      end
      csv
    end
  end

  def workload_params_as_hidden_field_tags(params)
    tags = ''
    params[:workload]&.each do |key, value|
      if value.is_a? Array
        tags += array_to_hidden_field(key, value)
      else
        tags += hidden_field_tag("workload[#{key}]", value)
      end
    end
    tags.html_safe
  end

  def array_to_hidden_field(key, value)
    tags = ''
    value.each do |entry|
      tags += hidden_field_tag("workload[#{key}][]", entry)
    end
    tags
  end
end
