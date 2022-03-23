# frozen_string_literal: true

##
# Provides methods for building the workload table. These methods are used in
# WorkloadsController and its views.
#
module ListUser
  class << self
    ##
    # Returns all issues that fulfill the following conditions:
    #  * They are open
    #  * The project they belong to is active
    #
    # @param users [Array(User)] An array of user objects.
    # @return [ActiveRecord::Relation(Isue)] The set of issues meeting the
    #                                        conditions above.
    #
    #
    def open_issues_for_users(users)
      raise ArgumentError unless users.is_a?(Array)

      userIDs = users.map(&:id)

      issue = Issue.arel_table
      project = Project.arel_table
      issue_status = IssueStatus.arel_table

      # Fetch all issues that ...
      issues = Issue.joins(:project)
                    .joins(:status)
                    .joins(:assigned_to)
                    .where(issue[:assigned_to_id].in(userIDs))      # Are assigned to one of the interesting users
                    .where(project[:status].eq(1))                  # Do not belong to an inactive project
                    .where(issue_status[:is_closed].eq(false))      # Is open

      # Filter out all issues that have children; They do not *directly* add to
      # the workload
      issues.select(&:leaf?)
    end

    ##
    # Returns the hours per day in the given time span (including firstDay and
    # lastDay) for each open issue of each of the given users.
    # The result is returned as nested hash:
    # The topmost hash takes a user object as key and returns a hash that takes
    # among others a project as key.
    # The projects hash takes among others an issue as key which again
    # returns the day related data in another hash as returned by 
    # ListUser.hours_for_issue_per_day.
    #
    # @example Returned hash for a two day time span
    #
    #  { #<User id: 12, ...> => { :overdue_hours => 0.0,
    #                             :overdue_number => 0,
    #                             :total => { Sat, 12 Mar 2022 => { :hours=>0.0, :holiday=>true },
    #                                         Sun, 13 Mar 2022 => { :hours=>0.0, :holiday=>true } },
    #                             :invisible => {},
    #                             #<Project id: 4711, ...> => { :total => { Sat, 12 Mar 2022=>{:hours=>0.0, :holiday=>true},
    #                                                                       Sun, 13 Mar 2022=>{:hours=>0.0, :holiday=>true} },
    #                                                           :overdue_hours => 0.0,
    #                                                           :overdue_number => 0,
    #                                                           #<Issue id: 12176, ...> => { Sat, 12 Mar 2022 => { :hours => 0.0,
    #                                                                                                              :active => true,
    #                                                                                                              :noEstimate => false,
    #                                                                                                              :holiday => true },
    #                                                                                        Sun, 13 Mar 2022 => { :hours => 0.0,
    #                                                                                                              :active => true, 
    #                                                                                                              :noEstimate => false,
    #                                                                                                              :holiday => true } } } }
    #
    # Additionally, the returned hash has two special keys:
    # * :invisible. Returns a summary of all issues that are not visible for the
    #								currently logged in user.
    # ´* :total.    Returns a summary of all issues for the user that this hash is
    #								for.
    # @return [Hash] Hash with all relevant data for displaying the workload table
    #                on user base.
    def hours_per_user_issue_and_day(issues, timeSpan, today)
      raise ArgumentError unless issues.is_a?(Array)
      raise ArgumentError unless timeSpan.is_a?(Range)
      raise ArgumentError unless today.is_a?(Date)

      result = {}

      issues.each do |issue|
        assignee = issue.assigned_to

        workingDays = DateTools.getWorkingDaysInTimespan(timeSpan, assignee.id)
        firstWorkingDayFromTodayOn = workingDays.select { |x| x >= today }.min || today

        unless result.key?(issue.assigned_to)
          result[assignee] = {
            overdue_hours: 0.0,
            overdue_number: 0,
            total: {},
            invisible: {}
          }

          timeSpan.each do |day|
            result[assignee][:total][day] = {
              hours: 0.0,
              holiday: workingDays.exclude?(day)
            }
          end
        end

        hoursForIssue = hours_for_issue_per_day(issue, timeSpan, today)

        # Add the issue to the total workload, unless its overdue.
        if issue.overdue?
          result[assignee][:overdue_hours] += hoursForIssue[firstWorkingDayFromTodayOn][:hours]
          result[assignee][:overdue_number] += 1
        else
          result[assignee][:total] = add_issue_info_to_summary(result[assignee][:total], hoursForIssue, timeSpan)
        end

        # If the issue is invisible, add it to the invisible issues summary.
        # Otherwise, add it to the project (and its summary) to which it belongs
        # to.
        if issue.visible?
          project = issue.project

          unless result[assignee].key?(project)
            result[assignee][project] = {
              total: {},
              overdue_hours: 0.0,
              overdue_number: 0
            }

            timeSpan.each do |day|
              result[assignee][project][:total][day] = {
                hours: 0.0,
                holiday: workingDays.exclude?(day)
              }
            end
          end

          # Add the issue to the project workload summary, unless its overdue.
          if issue.overdue?
            result[assignee][project][:overdue_hours] += hoursForIssue[firstWorkingDayFromTodayOn][:hours]
            result[assignee][project][:overdue_number] += 1
          else
            result[assignee][project][:total] =
              add_issue_info_to_summary(result[assignee][project][:total], hoursForIssue, timeSpan)
          end

          # Add it to the issues for that project in any case.
          result[assignee][project][issue] = hoursForIssue
        else
          unless issue.overdue?
            result[assignee][:invisible] =
              add_issue_info_to_summary(result[assignee][:invisible], hoursForIssue, timeSpan)
          end
        end
      end

      result
    end

    private

    ##
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
    # @param issue [Issue] A single issue object.
    # @param timespan [Range] Relevant time span.
    # @param today [Date] The date of today.
    #
    # @return [Hash] If the given time span is empty, an empty hash is returned.
    #
    def hours_for_issue_per_day(issue, timeSpan, today)
      raise ArgumentError unless issue.is_a?(Issue)
      raise ArgumentError unless timeSpan.is_a?(Range)
      raise ArgumentError unless today.is_a?(Date)

      hoursRemaining = estimated_time_for_issue(issue)
      assignee = issue.assigned_to.nil? ? 'all' : issue.assigned_to.id
      workingDays = DateTools.getWorkingDaysInTimespan(timeSpan, assignee)

      result = {}

      # If issue is overdue and the remaining time may be estimated, all
      # remaining hours are put on first working day.
      if !issue.due_date.nil? && (issue.due_date < today)

        # Initialize all days to inactive
        timeSpan.each do |day|
          # A day is active if it is after the issue start and before the issue due date
          isActive = (day <= issue.due_date && (issue.start_date.nil? || issue.start_date >= day))

          result[day] = {
            hours: 0.0,
            active: isActive,
            noEstimate: false,
            holiday: workingDays.exclude?(day)
          }
        end

        firstWorkingDayAfterToday = DateTools.getWorkingDaysInTimespan(today..timeSpan.end, assignee).min
        result[firstWorkingDayAfterToday] = {} if result[firstWorkingDayAfterToday].nil?
        result[firstWorkingDayAfterToday][:hours] = hoursRemaining

      # If the hours needed for an issue can not be estimated, set all days
      # outside the issues time to inactive, and all days within the issues time
      # to active but not estimated.
      elsif issue.due_date.nil? || issue.start_date.nil?
        timeSpan.each do |day|
          isHoliday = workingDays.exclude?(day)

          # Check: Is the issue is active on day?
          result[day] = if (!issue.due_date.nil? && (day <= issue.due_date)) ||
                          (!issue.start_date.nil? && (day >= issue.start_date)) ||
                          (issue.start_date.nil? && issue.due_date.nil?)

                          {
                            hours: 0.0, # No estimate possible, use zero
                            # to make other calculations easy.
                            active: true,
                            noEstimate: true && !isHoliday, # On holidays, the zero hours
                            # are *not* estimated
                            holiday: isHoliday
                          }

                        # Issue is not active
                        else
                          {
                            hours: 0.0, # Not active => 0 hours to do.
                            active: false,
                            noEstimate: false,
                            holiday: isHoliday
                          }
                        end
        end

      # The issue has start and end date
      else
        # Number of remaining working days for the issue:
        numberOfWorkdaysForIssue = DateTools.getRealDistanceInDays([today, issue.start_date].max..issue.due_date,
                                                                  assignee)

        hoursPerWorkday = hoursRemaining / numberOfWorkdaysForIssue.to_f

        timeSpan.each do |day|
          isHoliday = workingDays.exclude?(day)

          result[day] = if (day >= issue.start_date) && (day <= issue.due_date)

                          if day >= today
                            {
                              hours: isHoliday ? 0.0 : hoursPerWorkday,
                              active: true,
                              noEstimate: issue.estimated_hours.nil? && !isHoliday,
                              holiday: isHoliday
                            }
                          else
                            {
                              hours: 0.0,
                              active: true,
                              noEstimate: false,
                              holiday: isHoliday
                            }
                          end
                        else
                          {
                            hours: 0.0,
                            active: false,
                            noEstimate: false,
                            holiday: isHoliday
                          }
                        end
        end
      end

      result
    end

    ##
    # Calculates the issues estimated hours weighted by its unfinished ratio.
    #
    # @param issue [Issue] The issue object with relevant estimated hours.
    # @return [Float] The decimal number of remaining working hours.
    #
    #
    def estimated_time_for_issue(issue)
      raise ArgumentError unless issue.is_a?(Issue)

      return 0.0 if issue.estimated_hours.nil?
      return 0.0 if issue.children.any?

      issue.estimated_hours * ((100.0 - issue.done_ratio) / 100.0)
    end

    ##
    # Prepares a summary of issue infos.
    #
    # @param summary
    # @param issue_info
    # @param time_span
    #
    def add_issue_info_to_summary(summary, issue_info, time_span)
      working_days = DateTools.getWorkingDaysInTimespan(time_span)
      summary ||= {}

      time_span.each do |day|
        summary[day] = { hours: 0.0, holiday: working_days.exclude?(day) } unless summary.key?(day)
        summary[day][:hours] += issue_info[day][:hours]
      end

      summary
    end
  end
end
