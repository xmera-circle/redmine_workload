class DateTools

  # Returns a list of all regular working weekdays.
  # 1 is monday, 7 is sunday (same as in Date::cwday)
  def self.getWorkingDays()
    result = []

    result.push(1) if Setting.plugin_redmine_workload['general_workday_monday'] != ''
    result.push(2) if Setting.plugin_redmine_workload['general_workday_tuesday'] != ''
    result.push(3) if Setting.plugin_redmine_workload['general_workday_wednesday'] != ''
    result.push(4) if Setting.plugin_redmine_workload['general_workday_thursday'] != ''
    result.push(5) if Setting.plugin_redmine_workload['general_workday_friday'] != ''
    result.push(6) if Setting.plugin_redmine_workload['general_workday_saturday'] != ''
    result.push(7) if Setting.plugin_redmine_workload['general_workday_sunday'] != ''

    return result
  end

  def self.getWorkingDaysInTimespan(timeSpan)
    raise ArgumentError unless timeSpan.kind_of?(Range)

    workingDays = self::getWorkingDays()

    result = []

    timeSpan.each do |day|
      if workingDays.include?(day.cwday) then
        result.push(day)
      end
    end

    return result
  end

  def self.getRealDistanceInDays(timeSpan)
    raise ArgumentError unless timeSpan.kind_of?(Range)

    return self::getWorkingDaysInTimespan(timeSpan).count
  end
end
