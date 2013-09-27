# -*- encoding : utf-8 -*-
class DateTools

  # Returns a list of all regular working weekdays.
  # 1 is monday, 7 is sunday (same as in Date::cwday)
  def self.getWorkingDays()
    result = Set::new

    result.add(1) if Setting['plugin_redmine_workload']['general_workday_monday'] != ''
    result.add(2) if Setting['plugin_redmine_workload']['general_workday_tuesday'] != ''
    result.add(3) if Setting['plugin_redmine_workload']['general_workday_wednesday'] != ''
    result.add(4) if Setting['plugin_redmine_workload']['general_workday_thursday'] != ''
    result.add(5) if Setting['plugin_redmine_workload']['general_workday_friday'] != ''
    result.add(6) if Setting['plugin_redmine_workload']['general_workday_saturday'] != ''
    result.add(7) if Setting['plugin_redmine_workload']['general_workday_sunday'] != ''

    return result
  end

  @@getWorkingDaysInTimespanCache = Hash::new

  def self.getWorkingDaysInTimespan(timeSpan, noCache = false)
    raise ArgumentError unless timeSpan.kind_of?(Range)

    return @@getWorkingDaysInTimespanCache[timeSpan] unless @@getWorkingDaysInTimespanCache[timeSpan].nil? || noCache

    workingDays = self::getWorkingDays()

    result = Set::new

    timeSpan.each do |day|
      if workingDays.include?(day.cwday) then
        result.add(day)
      end
    end

    @@getWorkingDaysInTimespanCache[timeSpan] = result

    return result
  end

  def self.getRealDistanceInDays(timeSpan)
    raise ArgumentError unless timeSpan.kind_of?(Range)

    return self::getWorkingDaysInTimespan(timeSpan).size
  end
end
