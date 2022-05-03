# frozen_string_literal: true

##
# Summarize the workload of a whole group and integrate its members including
# the group user dummy.
#
class GroupWorkload
  attr_reader :time_span, :user_workload

  def initialize(users:, user_workload:, time_span:)
    self.users = users
    self.user_workload = user_workload
    self.time_span = time_span
    self.selected_groups = users.groups&.selected
    self.group_members = select_group_members
  end

  ##
  #
  # @return [Hash(Group, UserWorkload#hours_per_user_issue_and_day)] Hash with
  #  results of UserWorkload#hours_per_user_issue_and_day for each group.
  def by_group
    selected_groups.each_with_object({}) do |group, hash|
      summary = summarize_over_group_members(group)
      hash[group] = summary.merge(group_members[group])
    end
  end

  private

  attr_accessor :users, :selected_groups, :group_members
  attr_writer :time_span, :user_workload

  def select_group_members
    selected_groups&.each_with_object({}) do |group, hash|
      hash[group] = sorted_user_workload.select { |user, _data| user.groups.include? group }
    end
  end

  def sorted_user_workload
    user_workload_with_availabilities.sort_by { |user, _data| [user.class.name, user.lastname] }.to_h
  end

  def user_workload_with_availabilities
    availabilities = users.selected - assignees
    availabilities.each do |user|
      user_workload[user] = { total: total_availabilities_of(user) }
    end
    user_workload
  end

  def total_availabilities_of(user)
    working_days = WlDateTools.working_days_in_time_span(time_span, user.id)
    time_span.each_with_object({}) do |day, hash|
      hash[day] = {}
      hash[day][:hours] = 0.0
      hash[day][:holiday] = working_days.exclude?(day)
    end
  end

  def assignees
    user_workload.keys
  end

  def summarize_over_group_members(group)
    { overdue_hours: sum_of(:overdue_hours, group),
      overdue_number: sum_of(:overdue_number, group),
      total: total_of_group_members(group),
      invisible: invisibles_of_group_members(group) }
  end

  def sum_of(key, group)
    group_members[group].sum { |_member, data| data[key.to_sym] || 0 }
  end

  def total_of_group_members(group)
    time_span.each_with_object({}) do |day, hash|
      hash[day] = {}
      hash[day][:hours] = hours_at(day, :total, group)
      hash[day][:holiday] = holiday_at(day, :total, group)
    end
  end

  def invisibles_of_group_members(group)
    invisible = time_span.each_with_object({}) do |day, hash|
      hours = hours_at(day, :invisible, group)
      holidays = holiday_at(day, :invisible, group)

      hash[day] = {}
      hash[day][:hours] = hours
      hash[day][:holiday] = holidays
    end
    invisible.any? { |_date, data| data[:hours].positive? } ? invisible : nil
  end

  def hours_at(day, key, group)
    group_members[group].sum { |_member, data| data.dig(key.to_sym, day, :hours) || 0 }
  end

  def holiday_at(day, key, group)
    values = group_members[group].map { |_member, data| data.dig(key.to_sym, day, :holiday) }
    values.uniq[0]
  end
end
