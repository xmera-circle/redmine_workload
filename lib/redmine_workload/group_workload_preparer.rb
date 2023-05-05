# frozen_string_literal: true

module RedmineWorkload

require 'forwardable'

module RedmineWorkload
  class GroupWorkloadPreparer
    include Redmine::I18n
    extend Forwardable

    def_delegators :data, :user_workload, :time_span

    attr_reader :data, :params

    def initialize(data:, params:)
      self.data = data
      self.params = params
    end

    def group_workload
      data.by_group
    end

    def type(assignee)
      case assignee.class.name
      when 'Group'
        l(:label_aggregation)
      else
        assignee.type
      end
    end

    def main_group(assignee)
      case assignee.class.name
      when 'User'
        user_group = assignee.main_group_id
        assignee.groups.find_by(id: user_group)&.name
      when 'GroupUserDummy'
        assignee.main_group&.name
      else
        ''
      end
    end

    private

    attr_writer :data, :params
  end
end

end