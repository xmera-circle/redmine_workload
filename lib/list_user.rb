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
  def self.getOpenIssuesForUsersActiveInGivenTimeSpan(users, firstDay, lastDay)

    firstDay = firstDay.to_date if firstDay.respond_to?(:to_date)
    lastDay  = lastDay.to_date  if lastDay.respond_to?(:to_date)

    # Check that the given time span is valid.
    return [] if lastDay < firstDay

    userIDs = users.map(&:id)

    issue = Issue.arel_table
    project = Project.arel_table
    issue_status = IssueStatus.arel_table

    # Fetch all issues that ...
    issues = Issue.joins(:project).
                   joins(:status).
                        where(issue[:assigned_to_id].in(userIDs)).  # Are assigned to one of the interesting users
                        where(project[:status].eq(1)).              # Do not belong to an inactive project
                        where(issue[:start_date].not_eq(nil)).      # Have a start date
                        where(issue[:due_date].not_eq(nil)).        # Have an end date
                        where(issue[:start_date].gt(lastDay).not).  # Start *not* after the given time span
                        where(issue[:due_date].lt(firstDay).not).   # End *not* before the given time span
                        where(issue_status[:is_closed].eq(false))   # Is open

    return issues
  end

  # Returns one day of each month between the given dates, including the months
  # of the dates. It is not specified which day of the month will be returned.
  def self.getMonthsBetween(firstDay, lastDay)

    firstDay  = firstDay.to_date  if firstDay.respond_to?(:to_date)
    lastDay   = lastDay.to_date   if lastDay.respond_to?(:to_date)

    # Abort if the given time span is empty.
    return [] if firstDay > lastDay

    firstOfCurrentMonth = firstDay.beginning_of_month
    firstOfLastMonth    = lastDay.beginning_of_month

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
