# frozen_string_literal: true

require 'forwardable'

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
    l(:label_aggregation)
  end

  def main_group(assignee)
    case assignee.class
    when User
      user_group = assignee.wl_user_data&.main_group
      assignee.groups.find(user_group)&.name 
    when GroupUserDummy
      assignee.main_group&.name
    else
      ''
    end
  end

  private

  attr_writer :data, :params
end
