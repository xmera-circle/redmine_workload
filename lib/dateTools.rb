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
  
  def self.getWorkingDaysInTimespan(timeSpan, user = 'all', noCache = false)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    
    Rails.cache.clear if noCache
    
    return Rails.cache.fetch("#{user}/#{timeSpan}", expires_in: 12.hours) do
    
      workingDays = self::getWorkingDays()    
  
      result = Set::new
  
      timeSpan.each do |day|#
        next if self::IsVacation(day, user) ##skip Vacation
        next if self::IsHoliday(day) ##skip Holidays
  
        if workingDays.include?(day.cwday) then
          result.add(day)
        end
      end

      result      
    end 

  end

  def self.getRealDistanceInDays(timeSpan, assignee='all')
    raise ArgumentError unless timeSpan.kind_of?(Range)    
    return self::getWorkingDaysInTimespan(timeSpan, assignee).size
  end
    
  def self.IsHoliday(day)
    if WlNationalHoliday.where("start <= ? AND end >= ?", day, day).empty? then
      return false
    else
      return true
    end
  end
  
  def self.IsVacation(day, user)
    return false if user=='all'
    
    if WlUserVacation.where("user_id = ? AND date_from <= ? AND date_to >= ?", user, day, day).empty? then
      return false
    else
      return true
    end
  end
  
end
