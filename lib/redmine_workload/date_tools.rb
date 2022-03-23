# frozen_string_literal: true

class DateTools
  ##
  # Returns an array with one entry for each month in the given time span.
  # Each entry is a hash with two keys: :first_day and :last_day, having the
  # first resp. last day of that month from the time span as value.
  # @param timespan [Range] Timespan
  # @return [Array(Hash)] Array with one entry for each month in the given time span
  #
  def self.months_in_timespan(timeSpan)
    raise ArgumentError unless timeSpan.is_a?(Range)

    # Abort if the given time span is empty.
    return [] unless timeSpan.any?

    firstOfCurrentMonth = timeSpan.first
    lastOfCurrentMonth  = [firstOfCurrentMonth.end_of_month, timeSpan.last].min

    result = []
    while firstOfCurrentMonth <= timeSpan.last
      result.push({
                    first_day: firstOfCurrentMonth,
                    last_day: lastOfCurrentMonth
                  })

      firstOfCurrentMonth = firstOfCurrentMonth.beginning_of_month.next_month
      lastOfCurrentMonth  = [firstOfCurrentMonth.end_of_month, timeSpan.last].min
    end

    result
  end

  # Returns a list of all regular working weekdays.
  # 1 is monday, 7 is sunday (same as in Date::cwday)
  def self.getWorkingDays
    result = Set.new

    result.add(1) if Setting['plugin_redmine_workload']['general_workday_monday'] != ''
    result.add(2) if Setting['plugin_redmine_workload']['general_workday_tuesday'] != ''
    result.add(3) if Setting['plugin_redmine_workload']['general_workday_wednesday'] != ''
    result.add(4) if Setting['plugin_redmine_workload']['general_workday_thursday'] != ''
    result.add(5) if Setting['plugin_redmine_workload']['general_workday_friday'] != ''
    result.add(6) if Setting['plugin_redmine_workload']['general_workday_saturday'] != ''
    result.add(7) if Setting['plugin_redmine_workload']['general_workday_sunday'] != ''

    result
  end

  def self.getWorkingDaysInTimespan(timeSpan, user = 'all', no_cache: false)
    raise ArgumentError unless timeSpan.is_a?(Range)

    Rails.cache.clear if no_cache

    Rails.cache.fetch("#{user}/#{timeSpan}", expires_in: 12.hours) do
      workingDays = getWorkingDays

      result = Set.new

      timeSpan.each do |day| #
        next if self::IsVacation(day, user) # #skip Vacation
        next if self::IsHoliday(day) # #skip Holidays

        result.add(day) if workingDays.include?(day.cwday)
      end

      result
    end
  end

  def self.getRealDistanceInDays(timeSpan, assignee = 'all')
    raise ArgumentError unless timeSpan.is_a?(Range)

    getWorkingDaysInTimespan(timeSpan, assignee).size
  end

  def self.IsHoliday(day)
    !WlNationalHoliday.where('start <= ? AND end >= ?', day, day).empty?
  end

  def self.IsVacation(day, user)
    return false if user == 'all'

    !WlUserVacation.where('user_id = ? AND date_from <= ? AND date_to >= ?', user, day, day).empty?
  end
end
