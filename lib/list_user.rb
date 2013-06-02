class ListUser
  unloadable

  def initialize(openstatus)
      @openstatus = openstatus
  end

  # Returns all issues that fulfill the following conditions:
  #  * They are open,
  #  * The project they belong to is active,
  #  * Due date and start date are set,
  #  * They have at least on day in the given timespan.
  def self.getOpenIssuesForUsersActiveInTimeSpan(users, timeSpan)

    raise ArgumentError unless timeSpan.kind_of?(Range)
    raise ArgumentError unless users.kind_of?(Array)

    return [] unless timeSpan.any?

    userIDs = users.map(&:id)

    issue = Issue.arel_table
    project = Project.arel_table
    issue_status = IssueStatus.arel_table

    # Fetch all issues that ...
    issues = Issue.joins(:project).
                   joins(:status).
                   joins(:assigned_to).
                        where(issue[:assigned_to_id].in(userIDs)).      # Are assigned to one of the interesting users
                        where(project[:status].eq(1)).                  # Do not belong to an inactive project
                        where(issue[:start_date].not_eq(nil)).          # Have a start date
                        where(issue[:due_date].not_eq(nil)).            # Have an end date
                        where(issue[:start_date].gt(timeSpan.end).not). # Start *not* after the given time span
                        where(issue[:due_date].lt(timeSpan.begin).not). # End *not* before the given time span
                        where(issue_status[:is_closed].eq(false))       # Is open

    return issues
  end

  # Returns the hours per day for the given issue. The result is only computed
  # for days in the given time span. The function assumes that firstDay is
  # today, so all remaining hours need to be done on or after firstDay.
  # If the issue is overdue, all hours are assigned to the first working day
  # after firstDay, or to firstDay itself, if it is a working day.
  #
  # The result is a hash taking a Date as key and returning a hash with the
  # following keys:
  #   * :hours - the hours needed on that day
  #   * :active - true if the issue is active on that day, false else
  #   * :noEstimate - no estimated hours calculated because the issue has
  #                   no estimate set or either start-time or end-time are not
  #                   set.
  #   * :holiday - true if this is a holiday, false otherwise.
  #
  # If the given time span is empty, an empty hash is returned.
  def self.getHoursForIssuesPerDay(issue, timeSpan, today)

    raise ArgumentError unless issue.kind_of?(Issue)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    raise ArgumentError unless today.kind_of?(Date)

    # Calculate the number of remaining hours for the issue, if possible.
    if !issue.estimated_hours.nil? then
      hoursRemaining = issue.estimated_hours.to_f * (1.0 - issue.done_ratio.to_f/100.0)
    else
      hoursRemaining = 0.0
    end

    result = Hash::new

    workingDays = DateTools::getWorkingDaysInTimespan(timeSpan)

    # If issue is overdue and the remaining time may be estimated, all
    # remaining hours are put on first working day.
    if !issue.due_date.nil? && (issue.due_date < today) then

      # Initialize all days to inactive
      timeSpan.each do |day|

        # A day is active if it is after the issue start and before the issue due date
        isActive = (day <= issue.due_date && (issue.start_date.nil? || issue.start_date >= day))

        result[day] = {
          :hours => 0.0,
          :active => isActive,
          :noEstimate => false,
          :holiday => !workingDays.include?(day)
        }
      end

      firstWorkingDayAfterToday = DateTools::getWorkingDaysInTimespan(today..timeSpan.end).first
      result[firstWorkingDayAfterToday][:hours] = hoursRemaining

    # If the hours needed for an issue can not be estimated, set all days
    # outside the issues time to inactive, and all days within the issues time
    # to active but not estimated.
    elsif issue.due_date.nil? || issue.start_date.nil? then
      timeSpan.each do |day|

        isHoliday = !workingDays.include?(day)

        # Check: Is the issue is active on day?
        if ( (!issue.due_date.nil?)   && (day <= issue.due_date)  ) ||
           ( (!issue.start_date.nil?) && (day >= issue.start_date)) ||
           (   issue.start_date.nil?  &&  issue.due_date.nil?     ) then

          result[day] = {
            :hours => 0.0,                     # No estimate possible, use zero
                                               # to make other calculations easy.
            :active => true,
            :noEstimate => true && !isHoliday, # On holidays, the zero hours
                                               # are *not* estimated
            :holiday => isHoliday
          }

        # Issue is not active
        else
          result[day] = {
            :hours => 0.0,        # Not active => 0 hours to do.
            :active => false,
            :noEstimate => false,
            :holiday => isHoliday
          }
        end
      end

    # The issue has start and end date
    else
      # Number of remaining working days for the issue:
      numberOfWorkdaysForIssue = DateTools::getRealDistanceInDays([today, issue.start_date].max..issue.due_date)
      hoursPerWorkday = hoursRemaining/numberOfWorkdaysForIssue.to_f

      timeSpan.each do |day|

        isHoliday = !workingDays.include?(day)

        if (day >= issue.start_date) && (day <= issue.due_date) then

          if (day >= today) then
            result[day] = {
              :hours => isHoliday ? 0.0 : hoursPerWorkday,
              :active => true,
              :noEstimate => issue.estimated_hours.nil? && !isHoliday,
              :holiday => isHoliday
            }
          else
            result[day] = {
              :hours => 0.0,
              :active => true,
              :noEstimate => false,
              :holiday => isHoliday
            }
          end
        else
          result[day] = {
            :hours => 0.0,
            :active => false,
            :noEstimate => false,
            :holiday => isHoliday
          }
        end

      end
    end

    return result
  end

  # Returns the hours per day in the given time span (including firstDay and
  # lastDay) for each open issue of each of the given users.
  # The result is returned as nested hash:
  # The topmost hash takes a user as key and returns a hash that takes an issue
  # as key. This second hash returns a hash that was returned by
  # getHoursForIssuesPerDay.
  def self.getHoursPerUserIssueAndDay(users, timeSpan, today)
    raise ArgumentError unless users.kind_of?(Array)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    raise ArgumentError unless today.kind_of?(Date)

    issues = getOpenIssuesForUsersActiveInTimeSpan(users, timeSpan)

    result = {}

    issues.each do |issue|
      result[issue.assigned_to] = Hash::new unless result.has_key?(issue.assigned_to)
      result[issue.assigned_to][issue] = getHoursForIssuesPerDay(issue, timeSpan, today)
    end

    return result
  end

  # Returns one day of each month between the given dates, including the months
  # of the dates. It is not specified which day of the month will be returned.
  def self.getMonthsIn(timeSpan)

    raise ArgumentError unless timeSpan.kind_of?(Range)

    # Abort if the given time span is empty.
    return [] unless timeSpan.any?

    firstOfCurrentMonth = timeSpan.first.beginning_of_month
    firstOfLastMonth    = timeSpan.last.beginning_of_month

    result = []
    while firstOfCurrentMonth <= firstOfLastMonth do
      result.push(firstOfCurrentMonth)

      firstOfCurrentMonth = firstOfCurrentMonth.next_month
    end

    return result
  end

  # Returns the number of days of the month of the given day.
  def self.getDaysInMonth(day)
    day = day.to_date if day.respond_to?(:to_date)

    return day.end_of_month.day
  end

  # Adds the total workload for each day for a user. The first parameter must be
  # a data structure returned by getHoursPerUserIssueAndDay.
  # In this data structure, each used gets an additional key, :total_workload.
  # The result for this key is a hash that has the same structure as returned
  # by the function getHoursForIssuesPerDay.
  def self.calculateTotalUserWorkloads(hourDataStructure, timeSpan)

    workingDays = DateTools::getWorkingDaysInTimespan(timeSpan)

    hourDataStructure.keys.each do |user|
      # Get a list of all issues of the user. Filter, because other keys than
      # issues might be present.
      issuesOfUser = hourDataStructure[user].keys.select{|key| key.kind_of?(Issue)}

      hourDataStructure[user][:totalWorkload] = Hash::new
      totalWorkload = hourDataStructure[user][:totalWorkload]

      timeSpan.each do |day|

        # Initialize workload for day
        totalWorkload[day] = {
          :hours => 0.0,
          :holiday => !workingDays.include?(day)
        }

        # Go over all issues and sum workload
        issuesOfUser.each do |issue|
          totalWorkload[day][:hours] += hourDataStructure[user][issue][day][:hours]
        end
      end
    end
  end

  def getRemanente(user_id, date_end )
    issues_opened = getIssuesOpened(user_id, date_end)
    total = 0
    issues_opened.each do |sum|
      total+= sum.estimated_hours
    end
    return total
  end

  def getIssuesOpened(user_id, date_end)
    date_end = date_end.to_date.strftime("%Y-%m-%d") if date_end.respond_to?(:to_date)
    return Issue.find(:all,  :joins => :project, :conditions => [ " start_date < '#{date_end}' AND status_id = 1 AND assigned_to_id = #{user_id} AND estimated_hours IS NOT NULL AND projects.status = 1" ] )
  end

  def getIssuesOpenedWihtout(user_id, date_end)
    date_end = date_end.to_date.strftime("%Y-%m-%d") if date_end.respond_to?(:to_date)
    return Issue.find_all_by_status_id(@openstatus, :joins => :project, :conditions => [ "assigned_to_id = #{user_id} AND projects.status = 1 AND estimated_hours IS NULL" ] )
  end

  def issue_have_work(issue, day)
    if (issue.start_date.nil? || issue.due_date.nil? ) then
      return false
    end
    if(day.to_time >= issue.start_date.to_time && day.to_time <= issue.due_date.to_time )then
      return true
    end
    return false
  end

  def issue_is_parent(issue)
    if (issue.id.nil? || issue.root_id.nil? ) then
      return false
    end
    return (issue.id == issue.root_id && issue.parent_id.nil? && issue.children.count > 0 )
  end

  #def getIssuesOpenedEntreFechas(user_id, start_date, date_end )
  #   date_end = date_end.to_date.strftime("%Y-%m-%d") if date_end.respond_to?(:to_date)
  #   start_date = start_date.to_date.strftime("%Y-%m-%d") if start_date.respond_to?(:to_date)
  #  return Issue.find_all_by_status_id( @openstatus ,:joins => :project, :conditions => [ " ( due_date <= '#{date_end}' OR start_date >= '#{start_date}') AND assigned_to_id = #{user_id} AND start_date IS NOT NULL AND due_date IS NOT NULL AND estimated_hours IS NOT NULL AND projects.status = 1" ],   :order => 'root_id asc, id asc' )
  #end

  def getIssuesOpenedEntreFechas(user_id, start_date, date_end )
     date_end = date_end.to_date.strftime("%Y-%m-%d") if date_end.respond_to?(:to_date)
     start_date = start_date.to_date.strftime("%Y-%m-%d") if start_date.respond_to?(:to_date)
    return Issue.find_all_by_status_id( @openstatus ,:joins => :project, :conditions => [ " start_date <= '#{date_end}' AND due_date >= '#{start_date}' AND assigned_to_id = #{user_id} AND start_date IS NOT NULL AND due_date IS NOT NULL AND estimated_hours IS NOT NULL AND projects.status = 1" ],   :order => 'root_id asc, id asc' )
  end

  def sumIssuesTimes(merged)
    results = {}
    merged.each do |issue_arr|
      issue_arr.each do |key, value|

        if results.include?(key)then
            results[key] =  ( value > 0 && value.round == 0 ) ? results[key] + (value.round + 1) : results[key] + value.round
        else
            results[key] = ( value > 0 && value.round == 0 ) ? value.round + 1 :  value.round
        end
     end
   end
   return results
  end

  def parse_date(date)
    Date.parse date.gsub(/[{}\s]/, "").gsub(",", ".")
  end



end
