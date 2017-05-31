# -*- encoding : utf-8 -*-
class ListUser

  require 'dateTools'

  def self.getEstimatedTimeForIssue(issue)
    raise ArgumentError unless issue.kind_of?(Issue)

    return 0.0 if issue.estimated_hours.nil?
    return 0.0 if issue.children.any?

    return issue.estimated_hours*((100.0 - issue.done_ratio)/100.0)
  end

  # Returns all issues that fulfill the following conditions:
  #  * They are open
  #  * The project they belong to is active
  def self.getOpenIssuesForUsers(users)

    raise ArgumentError unless users.kind_of?(Array)

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
                        where(issue_status[:is_closed].eq(false))       # Is open

    #  Filter out all issues that have children; They do not *directly* add to
    # the workload
    return issues.select { |x| x.leaf? }
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

    hoursRemaining = ListUser::getEstimatedTimeForIssue(issue)
    issue.assigned_to.nil? ? assignee = 'all' : assignee = issue.assigned_to.id
    workingDays = DateTools::getWorkingDaysInTimespan(timeSpan, assignee )    

    result = Hash::new

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

      firstWorkingDayAfterToday = DateTools::getWorkingDaysInTimespan(today..timeSpan.end, assignee).min
      result[firstWorkingDayAfterToday] = Hash::new if result[firstWorkingDayAfterToday].nil?
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
      numberOfWorkdaysForIssue = DateTools::getRealDistanceInDays([today, issue.start_date].max..issue.due_date, assignee)
      
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
  # as key. This second hash takes a project as key and returns another hash.
	# This third level hash returns a hash that was returned by
	# getHoursForIssuesPerDay. Additionally, it has two special keys:
	# * :invisible. Returns a summary of all issues that are not visible for the
	#								currently logged in user.
	#´* :total.     Returns a summary of all issues for the user that this hash is
	#								for.
  def self.getHoursPerUserIssueAndDay(issues, timeSpan, today)
    raise ArgumentError unless issues.kind_of?(Array)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    raise ArgumentError unless today.kind_of?(Date)
		

		
    result = {}

    issues.each do |issue|
			
			assignee = issue.assigned_to
			
			workingDays = DateTools::getWorkingDaysInTimespan(timeSpan, assignee.id)
      firstWorkingDayFromTodayOn = workingDays.select {|x| x >= today}.min || today

			
      if !result.has_key?(issue.assigned_to) then
			result[assignee] = {
					:overdue_hours => 0.0,
					:overdue_number => 0,
					:total => Hash::new,
					:invisible => Hash::new
				}
					
				timeSpan.each do |day|
					result[assignee][:total][day] = {
						:hours => 0.0,
						:holiday => !workingDays.include?(day)
					}
				end
			end
			
			hoursForIssue = getHoursForIssuesPerDay(issue, timeSpan, today)

			# Add the issue to the total workload, unless its overdue.
			if issue.overdue? then
				result[assignee][:overdue_hours]  += hoursForIssue[firstWorkingDayFromTodayOn][:hours];
				result[assignee][:overdue_number] += 1
			else
				result[assignee][:total] = addIssueInfoToSummary(result[assignee][:total], hoursForIssue, timeSpan)
			end
		
			# If the issue is invisible, add it to the invisible issues summary.
			# Otherwise, add it to the project (and its summary) to which it belongs
			# to.
			if !issue.visible? then
				result[assignee][:invisible] = addIssueInfoToSummary(result[assignee][:invisible], hoursForIssue, timeSpan) unless issue.overdue?
			else
				project = issue.project
				
				if !result[assignee].has_key?(project) then
					result[assignee][project] = {
						:total => Hash::new,
						:overdue_hours => 0.0,
						:overdue_number => 0
					}
					
					timeSpan.each do |day|
						result[assignee][project][:total][day] = {
							:hours => 0.0,
							:holiday => !workingDays.include?(day)
						}
					end
				end

				# Add the issue to the project workload summary, unless its overdue.
				if issue.overdue? then
					result[assignee][project][:overdue_hours]  += hoursForIssue[firstWorkingDayFromTodayOn][:hours];
					result[assignee][project][:overdue_number] += 1
				else
					result[assignee][project][:total] = addIssueInfoToSummary(result[assignee][project][:total], hoursForIssue, timeSpan)
				end

				# Add it to the issues for that project in any case.
				result[assignee][project][issue] = hoursForIssue
			end
    end

    return result
  end

  # Returns an array with one entry for each month in the given time span.
  # Each entry is a hash with two keys: :first_day and :last_day, having the
  # first resp. last day of that month from the time span as value.
  def self.getMonthsInTimespan(timeSpan)

    raise ArgumentError unless timeSpan.kind_of?(Range)

    # Abort if the given time span is empty.
    return [] unless timeSpan.any?

    firstOfCurrentMonth = timeSpan.first
    lastOfCurrentMonth  = [firstOfCurrentMonth.end_of_month, timeSpan.last].min

    result = []
    while firstOfCurrentMonth <= timeSpan.last do
      result.push({
          :first_day => firstOfCurrentMonth,
          :last_day  => lastOfCurrentMonth
      })

      firstOfCurrentMonth = firstOfCurrentMonth.beginning_of_month.next_month
      lastOfCurrentMonth  = [firstOfCurrentMonth.end_of_month, timeSpan.last].min
    end

    return result
  end

  # Returns the "load class" for a given amount of working hours on a single
  # day.
  def self.getLoadClassForHours(hours, user = nil)
    raise ArgumentError unless hours.respond_to?(:to_f)
    hours = hours.to_f
    
    #load defaults:
    lowLoad = Setting['plugin_redmine_workload']['threshold_lowload_min'].to_f
    normalLoad = Setting['plugin_redmine_workload']['threshold_normalload_min'].to_f
    highLoad = Setting['plugin_redmine_workload']['threshold_highload_min'].to_f
    
    if !user.nil?
      user_workload_data = WlUserData.find_by user_id: user.id
      if !user_workload_data.nil?
        lowLoad     = user_workload_data.threshold_lowload_min
        normalLoad  = user_workload_data.threshold_normalload_min
        highLoad    = user_workload_data.threshold_highload_min
      end
    end

    if hours < lowLoad then
        return "none"
    elsif hours < normalLoad then
        return "low"
    elsif hours < highLoad then
        return "normal"
    else
        return "high"
    end      
    

  end

  # Returns the list of all users the current user may display.
  def self.getUsersAllowedToDisplay()

    return [] if User.current.anonymous?
    return User.active if User.current.admin?

    result = [User.current]

    # Get all projects where the current user has the :view_project_workload
    # permission
    projects = Project.allowed_to(:view_project_workload)

    projects.each do |project|
      result += project.members.map(&:user)
    end

    return result.uniq
  end

  def self.getUsersOfGroups(groups)
    result = [User.current]
    
    groups.each do |grp|
      #result += grp.members.map(&:user) if grp.members.map(&:user).nil?
      result += grp.users(&:users)
    end
    
    
    return result.uniq
  end

  def self.addIssueInfoToSummary(summary, issueInfo, timeSpan)
    workingDays = DateTools::getWorkingDaysInTimespan(timeSpan)
		
		summary = Hash::new if summary.nil?
		
		timeSpan.each do |day|
			if !summary.has_key?(day) then
				summary[day] = {:hours => 0.0, :holiday => !workingDays.include?(day)}
			end
			
			summary[day][:hours] += issueInfo[day][:hours]
		end

		return summary
	end
end
