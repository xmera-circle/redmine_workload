# frozen_string_literal: true

##
# Summarize the workload of a whole group and integrate its members including
# the group user dummy.
#
class GroupWorkload
  def initialize(user_workload:, selected_groups:, time_span:)
    self.user_workload = user_workload
    self.selected_groups = selected_groups
    self.time_span = time_span
  end

  def by_group
    selected_groups.each_with_object({}) do |group, hash|
      group_members = user_workload.select { |user, _data| user.groups.include? group }
      summary = summarize_over(group_members)
      hash[group] = summary.merge(group_members)
    end
  end

  private

  attr_accessor :user_workload, :selected_groups, :time_span

  def summarize_over(group_members)
    { overdue_hours: sum_of(:overdue_hours, group_members),
      overdue_number: sum_of(:overdue_number, group_members),
      total: total_of(group_members),
      invisible: invisibles_of(group_members) }
  end

  def sum_of(key, group_members)
    group_members.sum { |_member, data| data[key] || 0 }
  end

  def total_of(group_members)
    time_span.each_with_object({}) do |day, hash|
      hash[day] = {}
      hash[day][:hours] = group_members.sum { |_member, data| data.dig(:total, day, :hours) || 0 }
      hash[day][:holiday] = group_members.first[1].dig(:total, day, :holiday)
    end
  end

  def invisibles_of(group_members)
    time_span.each_with_object({}) do |day, hash|
      hash[day] = {}
      hash[day][:hours] = group_members.sum { |_member, data| data.dig(:invisible, day, :hours) || 0 }
      hash[day][:holiday] = group_members.first[1].dig(:invisible, day, :holiday)
    end
  end
end
