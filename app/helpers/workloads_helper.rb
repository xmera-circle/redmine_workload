# frozen_string_literal: true

module WorkloadsHelper
  def render_action_links
    render partial: 'wl_shared/action_links'
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
  # @param hours [Float] The decimal number of hours.
  # @param lowload [Float] The threshold lowload min value.
  # @param normalload [Float] The threshold normalload min value.
  # @param highload [Float] The threshold highload min value.
  # @return [String] The css class for highlighting the hours in the workload table.
  #
  def load_class_for_hours(hours, lowload, normalload, highload)
    hours = hours.to_f

    if lowload && hours < lowload
      'none'
    elsif normalload && hours < normalload
      'low'
    elsif highload && hours < highload
      'normal'
    else
      'high'
    end
  end

  def groups?(groups)
    return false unless groups

    groups.selected.presence
  end

  def filter_type(groups)
    groups?(groups) ? 'groups' : 'users'
  end

  def workloads_to_csv(workload, params)
    prepare = WlCsvExporter.new(data: workload, params: params)
    Redmine::Export::CSV.generate(encoding: params[:encoding]) do |csv|
      csv << prepare.header_fields
      prepare.group_workload.each do |level, data|
        csv << prepare.line(level, data, :available) if level.instance_of? Group
        csv << prepare.line(level, data, :planned)
      end
      prepare.user_workload.each do |level, data|
        csv << prepare.line(level, data, :planned)
      end
      csv
    end
  end

  def workload_params_as_hidden_field_tags(params)
    tags = ''
    params[:workload]&.each do |key, value|
      tags += if value.is_a? Array
                array_to_hidden_field(key, value)
              else
                hidden_field_tag("workload[#{key}]", value)
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
