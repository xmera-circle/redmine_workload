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

  def self.distance_of_time_in_days(from_time, to_time = 0, inclusive = true)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    if inclusive then
      from_time = from_time - 86400 
    end
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_days = (((to_time.to_i - from_time.to_i).abs)/86400).round
    return (from_time > to_time ) ? "-#{distance_in_days}".to_i : distance_in_days
  end
  
  def self.stimated_days(  hours, days )
    return hours/days
  end

  def self.getRealDistanceInDays(firstDay, lastDay)
    firstDay = firstDay.to_date if firstDay.respond_to?(:to_date)
    lastDay = lastDay.to_date   if lastDay.respond_to?(:to_date)

    workingDays = self::getWorkingDays()
    
    days = 0

    while (firstDay <= lastDay ) do
      if workingDays.include?(firstDay.cwday) then
          days += 1
      end
      
      firstDay = firstDay.next
    end

    return days
  end

  def self.addCommercialDays(fecha,days)
    fecha = fecha.to_date if fecha.respond_to?(:to_date)
    while days > 0
      fecha = fecha.next
      if (fecha.cwday < 6 && !$holidays.include?(fecha.strftime("%Y-%m-%d") )) then
        days = days - 1
      end
    end
    
    return fecha.strftime("%Y-%m-%d")
  end
end
