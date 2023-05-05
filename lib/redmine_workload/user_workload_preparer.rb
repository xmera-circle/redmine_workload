# frozen_string_literal: true

module RedmineWorkload

require 'forwardable'

module RedmineWorkload
  class UserWorkloadPreparer
    include Redmine::I18n
    extend Forwardable

    def_delegators :data, :time_span

    attr_reader :data, :params

    def initialize(data:, params:)
      self.data = data
      self.params = params
    end

    def group_workload
      {}
    end

    def user_workload
      data.by_user
    end

    def type(assignee)
      assignee.type
    end

    def main_group(assignee)
      user_group = assignee.main_group_id
      assignee.groups.find_by(id: user_group)&.name
    end

    private

    attr_writer :data, :params
  end
end

end