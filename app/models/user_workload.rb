# frozen_string_literal: true

##
# Provides methods for building the workload table. These methods are used in
# WorkloadsController and its views.
#
class UserWorkload
  include Redmine::I18n
  include WlIssueQuery

  attr_reader :assignees, :issues, :time_span, :today

  def initialize(assignees:, time_span:, today:, issues: nil)
    self.assignees = assignees
    self.issues = open_issues_for_users(assignees, issues)
    self.time_span = time_span
    self.today = today
  end

  ##
  # Returns the hours per day in the given time span (including firstDay and
  # lastDay) for each open issue of each of the given users.
  # The result is returned as nested hash:
  # The topmost hash takes a user object as key and returns a hash that takes
  # among others a project as key.
  # The projects hash takes among others an issue as key which again
  # returns the day related data in another hash as returned by
  # UserWorkload#hours_for_issue_per_day.
  #
  # @example Returned hash for a two day time span
  #
  #  { #<User id: 12, ...> => { :overdue_hours => 0.0,
  #                             :overdue_number => 0,
  #                             :total => { Sat, 12 Mar 2022 => { :hours=>0.0, :holiday=>true },
  #                                         Sun, 13 Mar 2022 => { :hours=>0.0, :holiday=>true } },
  #                             :invisible => {},
  #                             #<Project id: 4711, ...> =>
  #                                 { :total => { Sat, 12 Mar 2022=>{:hours=>0.0, :holiday=>true},
  #                                               Sun, 13 Mar 2022=>{:hours=>0.0, :holiday=>true} },
  #                                   :overdue_hours => 0.0,
  #                                   :overdue_number => 0,
  #                                    #<Issue id: 12176, ...> => { Sat, 12 Mar 2022 => { :hours => 0.0,
  #                                                                                       :active => true,
  #                                                                                       :noEstimate => false,
  #                                                                                       :holiday => true },
  #                                                                 Sun, 13 Mar 2022 => { :hours => 0.0,
  #                                                                                       :active => true,
  #                                                                                       :noEstimate => false,
  #                                                                                       :holiday => true } } } }
  #
  # Additionally, the returned hash has two special keys:
  # * :invisible. Returns a summary of all issues that are not visible for the
  #								currently logged in user.
  # ´* :total.    Returns a summary of all issues for the user that this hash is
  #								for.
  # @return [Hash] Hash with all relevant data for displaying the workload table
  #                on user base.
  def hours_per_user_issue_and_day
    raise ArgumentError unless issues.is_a?(Array)
    raise ArgumentError unless time_span.is_a?(Range)
    raise ArgumentError unless today.is_a?(Date)

    result = {}

    issues.group_by(&:assigned_to).each do |assignee, issue_set|
      working_days = working_days_in_time_span(assignee: assignee)
      first_working_day_from_today_on = working_days.select { |day| day >= today }.min || today
      cap = WlDayCapacity.new(assignee: assignee)

      assignee = GroupUserDummy.new(group: assignee) if assignee.is_a? Group

      unless result.key?(assignee)
        result[assignee] = {
          overdue_hours: 0.0,
          overdue_number: 0,
          unscheduled_hours: 0.0,
          unscheduled_number: 0,
          total: {},
          invisible: {}
        }

        time_span.each do |day|
          holiday = working_days.exclude?(day)
          result[assignee][:total][day] = {
            hours: 0.0,
            holiday: holiday,
            lowload: threshold_at(cap, holiday, :lowload),
            normalload: threshold_at(cap, holiday, :normalload),
            highload: threshold_at(cap, holiday, :highload)
          }
        end
      end

      ## Iterate over each issue in the array
      issue_set.each do |issue|
        project = issue.project
        hours_for_issue = hours_for_issue_per_day(issue, cap, assignee)

        # Add the issue to the total workload unless its overdue or unscheduled.
        # @note issue.overdue? implies there is a due_date. In order to avoid
        #   double counting a missing start_date will be ignored as criteria of
        #   beeing unscheduled.
        if issue.overdue?
          result[assignee][:overdue_hours] += hours_for_issue[first_working_day_from_today_on][:hours]
          result[assignee][:overdue_number] += 1
        elsif issue.due_date.nil?
          result[assignee][:unscheduled_number] += 1
          result[assignee][:unscheduled_hours] += hours_for_issue[first_working_day_from_today_on][:hours]
        else
          result[assignee][:total] = add_issue_info_to_summary(result[assignee][:total], hours_for_issue, assignee)
        end

        # If the issue is invisible, add it to the invisible issues summary.
        # Otherwise, add it to the project (and its summary) to which it belongs
        # to.
        if issue.visible?
          unless result[assignee].key?(project)
            result[assignee][project] = {
              total: {},
              overdue_hours: 0.0,
              overdue_number: 0,
              unscheduled_hours: 0.0,
              unscheduled_number: 0
            }

            time_span.each do |day|
              holiday = working_days.exclude?(day)
              result[assignee][project][:total][day] = {
                hours: 0.0,
                holiday: holiday,
                lowload: threshold_at(cap, holiday, :lowload),
                normalload: threshold_at(cap, holiday, :normalload),
                highload: threshold_at(cap, holiday, :highload)
              }
            end
          end

          # Add the issue to the project workload summary unless its overdue or unscheduled.
          # @note issue.overdue? implies there is a due_date. In order to avoid
          #   double counting a missing start_date will be ignored as criteria of
          #   beeing unscheduled.
          if issue.overdue?
            result[assignee][project][:overdue_hours] += hours_for_issue[first_working_day_from_today_on][:hours]
            result[assignee][project][:overdue_number] += 1
          elsif issue.due_date.nil?
            result[assignee][project][:unscheduled_number] += 1
            result[assignee][project][:unscheduled_hours] += hours_for_issue[first_working_day_from_today_on][:hours]
          else
            result[assignee][project][:total] =
              add_issue_info_to_summary(result[assignee][project][:total], hours_for_issue, assignee)
          end

          # Add it to the issues for that project in any case.
          result[assignee][project][issue] = hours_for_issue
        else
          unless issue.overdue?
            result[assignee][:invisible] =
              add_issue_info_to_summary(result[assignee][:invisible], hours_for_issue, assignee)
          end
        end
      end
    end

    result
  end

  alias by_user hours_per_user_issue_and_day

  private

  attr_writer :assignees, :issues, :time_span, :today

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
  # @param time_span [Range] Relevant time span.
  # @param today [Date] The date of today.
  #
  # @return [Hash] If the given time span is empty, an empty hash is returned.
  #
  def hours_for_issue_per_day(issue, cap, assignee)
    raise ArgumentError unless issue.is_a?(Issue)
    raise ArgumentError unless time_span.is_a?(Range)
    raise ArgumentError unless today.is_a?(Date)

    hours_remaining = estimated_time_for_issue(issue)
    working_days = working_days_in_time_span(assignee: assignee)

    result = {}

    # If issue is overdue and the remaining time may be estimated, all
    # remaining hours are put on first working day.
    if !issue.due_date.nil? && (issue.due_date < today)

      # Initialize all days to inactive
      time_span.each do |day|
        # A day is active if it is after the issue start and before the issue due date
        is_active = (day <= issue.due_date && (issue.start_date.nil? || issue.start_date >= day))
        holiday = working_days.exclude?(day)

        result[day] = {
          hours: 0.0,
          active: is_active,
          noEstimate: false,
          holiday: holiday,
          lowload: threshold_at(cap, holiday, :lowload),
          normalload: threshold_at(cap, holiday, :normalload),
          highload: threshold_at(cap, holiday, :highload)
        }
      end

      first_working_day_after_today = WlDateTools.working_days_in_time_span(today..time_span.end, assignee).min
      result[first_working_day_after_today] = {} if result[first_working_day_after_today].nil?
      result[first_working_day_after_today][:hours] = hours_remaining

    # If the hours needed for an issue can not be estimated, set all days
    # outside the issues time to inactive, and all days within the issues time
    # to active but not estimated.
    elsif issue.due_date.nil? || issue.start_date.nil?
      time_span.each do |day|
        holiday = working_days.exclude?(day)

        # Check: Is the issue is active on day?
        result[day] = if (!issue.due_date.nil? && (day <= issue.due_date)) ||
                         (!issue.start_date.nil? && (day >= issue.start_date)) ||
                         (issue.start_date.nil? && issue.due_date.nil?)

                        {
                          hours: 0.0, # No estimate possible, use zero
                          # to make other calculations easy.
                          active: true,
                          noEstimate: true && !holiday, # On holidays, the zero hours
                          # are *not* estimated
                          holiday: holiday,
                          lowload: threshold_at(cap, holiday, :lowload),
                          normalload: threshold_at(cap, holiday, :normalload),
                          highload: threshold_at(cap, holiday, :highload)
                        }

                      # Issue is not active
                      else
                        {
                          hours: 0.0, # Not active => 0 hours to do.
                          active: false,
                          noEstimate: false,
                          holiday: holiday,
                          lowload: threshold_at(cap, holiday, :lowload),
                          normalload: threshold_at(cap, holiday, :normalload),
                          highload: threshold_at(cap, holiday, :highload)
                        }
                      end
      end

    # The issue has start and end date
    else
      # Number of remaining working days for the issue:
      remaining_time_span = [today, issue.start_date].max..issue.due_date
      number_of_workdays_for_issue = WlDateTools.real_distance_in_days(remaining_time_span, assignee)
      hours_per_workday = hours_remaining / number_of_workdays_for_issue.to_f

      time_span.each do |day|
        holiday = working_days.exclude?(day)

        result[day] = if (day >= issue.start_date) && (day <= issue.due_date)

                        if day >= today
                          hours = holiday ? 0.0 : hours_per_workday
                          {
                            hours: hours,
                            active: true,
                            noEstimate: issue.estimated_hours.nil? && !holiday,
                            holiday: holiday,
                            lowload: threshold_at(cap, holiday, :lowload),
                            normalload: threshold_at(cap, holiday, :normalload),
                            highload: threshold_at(cap, holiday, :highload)
                          }
                        else
                          {
                            hours: 0.0,
                            active: true,
                            noEstimate: false,
                            holiday: holiday,
                            lowload: threshold_at(cap, holiday, :lowload),
                            normalload: threshold_at(cap, holiday, :normalload),
                            highload: threshold_at(cap, holiday, :highload)
                          }
                        end
                      else
                        {
                          hours: 0.0,
                          active: false,
                          noEstimate: false,
                          holiday: holiday,
                          lowload: threshold_at(cap, holiday, :lowload),
                          normalload: threshold_at(cap, holiday, :normalload),
                          highload: threshold_at(cap, holiday, :highload)
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
  #
  def add_issue_info_to_summary(summary, issue_info, assignee)
    summary ||= {}

    time_span.each do |day|
      holiday = { hours: 0.0, holiday: working_days_in_time_span(assignee: assignee).exclude?(day) }
      summary[day] = holiday unless summary.key?(day)
      summary[day][:hours] += issue_info[day][:hours]
    end

    summary
  end

  ##
  # Collects all working days within a given time span.
  #
  def working_days_in_time_span(assignee:, no_cache: false)
    WlDateTools.working_days_in_time_span(time_span, assignee, no_cache: no_cache)
  end

  ##
  # Calculates the day and user dependent threshold value of the workload.
  #
  # @param cap [WlDayCapacity] An object able to calculate the workload day capacity.
  # @param holiday [Boolean] Either a true or false value.
  # @param key [Symbol|String] The short form of the threshold: lowload, normalload, highload.
  #
  def threshold_at(cap, holiday, key)
    cap.threshold_at(key, holiday)
  end
end
