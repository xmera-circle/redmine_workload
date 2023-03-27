# frozen_string_literal: true

module RedmineWorkload

require_relative 'wl_user_data_defaults'

class WlDateTools
  extend WlUserDataDefaults
  ##
  # Returns an array with one entry for each month in the given time span.
  # Each entry is a hash with two keys: :first_day and :last_day, having the
  # first resp. last day of that month from the time span as value.
  # @param time_span [Range] Time span
  # @return [Array(Hash)] Array with one entry for each month in the given time span
  #
  def self.months_in_time_span(time_span)
    raise ArgumentError unless time_span.is_a?(Range)

    # Abort if the given time span is empty.
    return [] unless time_span.any?

    first_of_current_month = time_span.first
    last_of_current_month  = [first_of_current_month.end_of_month, time_span.last].min

    result = []
    while first_of_current_month <= time_span.last
      result.push({
                    first_day: first_of_current_month,
                    last_day: last_of_current_month
                  })

      first_of_current_month = first_of_current_month.beginning_of_month.next_month
      last_of_current_month  = [first_of_current_month.end_of_month, time_span.last].min
    end

    result
  end

  # Returns a list of all regular working weekdays.
  # 1 is monday, 7 is sunday (same as in Date::cwday)
  def self.working_days
    result = Set.new

    result.add(1) if settings['general_workday_monday'] != ''
    result.add(2) if settings['general_workday_tuesday'] != ''
    result.add(3) if settings['general_workday_wednesday'] != ''
    result.add(4) if settings['general_workday_thursday'] != ''
    result.add(5) if settings['general_workday_friday'] != ''
    result.add(6) if settings['general_workday_saturday'] != ''
    result.add(7) if settings['general_workday_sunday'] != ''

    result
  end

  def self.working_days_in_time_span(time_span, assignee, no_cache: false)
    raise ArgumentError unless time_span.is_a?(Range)

    Rails.cache.clear if no_cache

    Rails.cache.fetch("#{assignee.id}/#{time_span}", expires_in: 12.hours) do
      result = Set.new

      time_span.each do |day|
        next if vacation?(day, assignee)
        next if holiday?(day)

        result.add(day) if working_days.include?(day.cwday)
      end

      result
    end
  end

  def self.real_distance_in_days(time_span, assignee)
    raise ArgumentError unless time_span.is_a?(Range)

    working_days_in_time_span(time_span, assignee).size
  end

  def self.holiday?(day)
    !WlNationalHoliday.where('start <= ? AND end >= ?', day, day).empty?
  end

  def self.vacation?(day, assignee)
    return false unless assignee.is_a?(User)

    !WlUserVacation.where('user_id = ? AND date_from <= ? AND date_to >= ?', assignee.id, day, day).empty?
  end
end

end