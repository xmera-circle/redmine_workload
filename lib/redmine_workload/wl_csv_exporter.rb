# frozen_string_literal: true

require 'forwardable'

module RedmineWorkload
  class WlCsvExporter
    include Redmine::I18n
    extend Forwardable

    def_delegators :data, :group_workload, :user_workload, :type, :time_span, :main_group

    attr_reader :data, :params

    def initialize(data:, params:)
      self.data = initialize_data_object(data)
      self.params = params
    end

    def header_fields
      static_column_names.map { |column| l("field_#{column}") } |
        dynamic_column_names
    end

    def line(assignee, workload, status)
      send("#{status}_line", assignee, workload)
    end

    private

    attr_writer :data, :params

    def initialize_data_object(data)
      return unless data

      klass = data.class
      "RedmineWorkload::#{klass}Preparer".constantize.new(data: data, params: params)
    end

    def validate_params

    end

    def planned_line(assignee, workload)
      [l(:label_planned),
      type(assignee),
      name(assignee),
      main_group(assignee),
      overdue_issues(workload),
      overdue_hours(workload),
      unscheduled_issues(workload),
      unscheduled_hours(workload),
      workload_over_time(workload)].flatten
    end

    def available_line(assignee, workload)
      [l(:label_available),
      type(assignee),
      name(assignee),
      '',
      '',
      '',
      '',
      '',
      max_capacities_over_time(workload)].flatten
    end

    def name(assignee)
      assignee.name
    end

    def overdue_issues(workload)
      workload[:overdue_number]
    end

    def overdue_hours(workload)
      workload[:overdue_hours]
    end

    def unscheduled_issues(workload)
      workload[:unscheduled_number]
    end

    def unscheduled_hours(workload)
      workload[:unscheduled_hours]
    end

    def workload_over_time(workload)
      data.time_span.map do |day|
        workload[:total][day][:hours]
      end
    end

    def max_capacities_over_time(workload)
      data.time_span.map do |day|
        workload[:total][day][:highload]
      end
    end

    def static_column_names
      %w[ status
          type
          name
          main_group
          number_of_overdue_issues
          number_of_overdue_hours
          number_of_unscheduled_issues
          number_of_unscheduled_hours]
    end

    def dynamic_column_names
      data.time_span.map { |date| format_date(date) }
    end
  end
end
