# -*- encoding : utf-8 -*-
class WorkLoadController < ApplicationController

  unloadable

  helper :gantt
  helper :issues
  helper :projects
  helper :queries
  helper :filters

  include QueriesHelper

  def show
    workloadParameters = params[:workload]

    workloadParameters = {} if workloadParameters.nil?

    # If no date is given for the start date, use today.
    @today = workloadParameters[:start_date].respond_to?(:to_date) ?
                    workloadParameters[:start_date].to_date :
                    Date::today

    # Get list of users that are allowed to display by this user
    @usersAllowedToDisplay = ListUser::getUsersAllowedToDisplay()

    # Get list of users that should be displayed.
    @usersToDisplay = workloadParameters[:users].nil? ?
                        [] :
                        User.find_all_by_id(workloadParameters[:users].split(','))

    # Intersect the list with the list of users that are allowed to be displayed.
    @usersToDisplay = @usersToDisplay & @usersAllowedToDisplay

    # Set the first day to display (must be begin of a month)
    @first_day = workloadParameters[:first_day].respond_to?(:to_date) ?
                    workloadParameters[:first_day].to_date.at_beginning_of_month :
                    Date::today.at_beginning_of_month

    # Use given number of months to display, or 2 if number cannot be parsed.
    workloadParameters[:num_months] = '2' if workloadParameters[:num_months].nil?
    @num_months = Integer(workloadParameters[:num_months]) rescue 2

    # Limit number of months to 12 to hold down runtimes.
    @num_months = [@num_months, 12].min

    # Last day is num_months after first day
    @last_day = (@first_day >> @num_months) - 1
    @timeSpanToDisplay = @first_day..@last_day

		
		@issuesForWorkload = ListUser::getOpenIssuesForUsers(@usersToDisplay)
    @monthsToRender = ListUser::getMonthsInTimespan(@timeSpanToDisplay)
    @workloadData   = ListUser::getHoursPerUserIssueAndDay(@issuesForWorkload, @timeSpanToDisplay, @today)
  end
end
