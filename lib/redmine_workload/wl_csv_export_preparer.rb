# frozen_string_literal: true

class WlCsvExportPreparer
  include Redmine::I18n

  attr_reader :data, :params

  def initialize(data:, params:)
    self.data = data
    self.params = params
  end

  def group_workload
    data.by_group
  end

  def user_workload
    data.send :user_workload
  end

  def header_fields
    static_column_names.map { |column| l("field_#{column}") } |
      dynamic_column_names
  end

  def line(assignee, workload)
    [l(:label_planned),
     type(assignee),
     name(assignee),
     main_group(assignee),
     overdue_issues(workload),
     overdue_hours(workload),
     workload_over_time(workload)].flatten
  end

  private

  attr_writer :data, :params

  def type(assignee)
    assignee.is_a?(Group) ? l(:label_aggregation) : assignee.type
  end

  def name(assignee)
    assignee.name
  end

  def main_group(assignee)
    return '' unless assignee.respond_to? :wl_user_data

    user_data = assignee.wl_user_data
    user_group = user_data ? user_data.main_group : assignee.main_group
    return user_group.name unless user_group.is_a? Integer

    assignee.groups.find(user_group)&.name
  end

  def overdue_issues(workload)
    workload[:overdue_number]
  end

  def overdue_hours(workload)
    workload[:overdue_hours]
  end

  def workload_over_time(workload)
    data.time_span.map do |day|
      workload[:total][day][:hours]
    end
  end

  def static_column_names
    %w[ status
        type
        name
        main_group
        number_of_overdue_issues
        number_of_overdue_hours]
  end

  def dynamic_column_names
    data.time_span.map { |date| format_date(date) }
  end
end
