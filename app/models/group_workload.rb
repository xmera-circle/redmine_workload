# frozen_string_literal: true

##
# Summarize the workload of a whole group and integrate its members including
# the group user dummy.
#
class GroupWorkload
  attr_reader :time_span, :user_workload

  ##
  # @param users [WlUserSelection] Users given as WlUserSelection object.
  # @param user_workload [UserWorkload] User workload given as UserWorkload object.
  # @param time_span [Range] A time span given as Range object.
  #
  def initialize(users:, user_workload:, time_span:)
    self.users = users
    self.user_workload = user_workload
    self.time_span = time_span
    self.selected_groups = define_selected_groups
    self.group_members = define_group_members
  end

  ##
  # Gives all aggregated data of the group and details for each user.
  #
  # @return [Hash(Group, UserWorkload#hours_per_user_issue_and_day)] Hash with
  #  results of UserWorkload#hours_per_user_issue_and_day for each group.
  def by_group
    selected_groups&.each_with_object({}) do |group, hash|
      summary = summarize_over_group_members(group)
      hash[group] = summary.merge(group_members[group])
    end
  end

  private

  attr_accessor :users, :selected_groups, :group_members
  attr_writer :time_span, :user_workload

  def define_selected_groups
    users.groups&.selected
  end

  ##
  # Select only those group members having their main group equal to the group
  # given.
  #
  def define_group_members
    selected_groups&.each_with_object({}) do |group, hash|
      hash[group] = sorted_user_workload.select { |user, _data| user.main_group_id == group.id }
    end
  end

  ##
  # Sorting of users lastname and their class name in order to ensure that the
  # GroupUserDummy will come first.
  #
  def sorted_user_workload
    user_workload_with_availabilities.sort_by { |user, _data| [user.class.name, user.lastname] }.to_h
  end

  ##
  # Adds those users which are selected but not considered for the workload
  # table since they have no issues assigned yet.
  #
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
      holiday = working_days.exclude?(day)
      capacity = WlDayCapacity.new(assignee: user)
      hash[day] = {}
      hash[day][:hours] = 0.0
      hash[day][:holiday] = holiday
      hash[day][:lowload] = capacity.threshold_at(:lowload, holiday)
      hash[day][:normalload] = capacity.threshold_at(:normalload, holiday)
      hash[day][:highload] = capacity.threshold_at(:highload, holiday)
    end
  end

  ##
  # Users having issues assigned and are therefore considered in user_workload
  # calculation.
  #
  def assignees
    user_workload.keys
  end

  def summarize_over_group_members(group)
    { overdue_hours: sum_of(:overdue_hours, group),
      overdue_number: sum_of(:overdue_number, group),
      unscheduled_number: sum_of(:unscheduled_number, group),
      unscheduled_hours: sum_of(:unscheduled_hours, group),
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
      hash[day][:lowload] = threshold_at(day, :lowload, group)
      hash[day][:normalload] = threshold_at(day, :normalload, group)
      hash[day][:highload] = threshold_at(day, :highload, group)
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

  ##
  # Checks for holiday of group members including GroupUserDummy, who never will
  # be on vacation, for a given day and returns true if all group members are in
  # holiday at a given day or false if not.
  #
  def holiday_at(day, key, group)
    values = group_members[group].map do |_member, data|
      data.dig(key.to_sym, day, :holiday)
    end
    values.compact.all?
  end

  ##
  # Sums up threshold values per day and group but ignores GroupUserDummy.
  #
  def threshold_at(day, key, group)
    group_members[group].sum do |member, data|
      member.is_a?(User) ? (data.dig(:total, day, key.to_sym) || 0.0) : 0.0
    end
  end
end
