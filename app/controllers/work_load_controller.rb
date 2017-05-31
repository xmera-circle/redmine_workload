# -*- encoding : utf-8 -*-
class WorkLoadController < ApplicationController

  unloadable

  helper :gantt
  helper :issues
  helper :projects
  helper :queries
  helper :workload_filters

  include QueriesHelper

  def show
    workloadParameters = params[:workload] || {}

    @first_day = sanitizeDateParameter(workloadParameters[:first_day],  Date::today - 10)
    @last_day  = sanitizeDateParameter(workloadParameters[:last_day],   Date::today + 50)
    @today     = sanitizeDateParameter(workloadParameters[:start_date], Date::today)

	  # if @today ("select as today") is before @first_day take @today as @first_day
	  @first_day = [@today, @first_day].min
	
    # Make sure that last_day is at most 12 months after first_day to prevent
    # long running times
    @last_day = [(@first_day >> 12) - 1, @last_day].min
    @timeSpanToDisplay = @first_day..@last_day

    initalizeUsers(workloadParameters)       
    

    @issuesForWorkload = ListUser::getOpenIssuesForUsers(@usersToDisplay)
    @monthsToRender = ListUser::getMonthsInTimespan(@timeSpanToDisplay)
    @workloadData   = ListUser::getHoursPerUserIssueAndDay(@issuesForWorkload, @timeSpanToDisplay, @today)
  end



private

  def initalizeUsers(workloadParameters)
    @groupsToDisplay=Group.all.sort_by { |n| n[:lastname] }
    
    groupIds = workloadParameters[:groups].kind_of?(Array) ? workloadParameters[:groups] : []
    groupIds.map! { |x| x.to_i }
    
    # Find selected groups:
    @selectedGroups =Group.where(:id => groupIds)
    
    @selectedGroups = @selectedGroups & @groupsToDisplay
    
    @usersToDisplay=ListUser::getUsersOfGroups(@selectedGroups)

    # Get list of users that are allowed to be displayed by this user sort by lastname
    @usersAllowedToDisplay = ListUser::getUsersAllowedToDisplay().sort_by { |u| u[:lastname] }

    userIds = workloadParameters[:users].kind_of?(Array) ? workloadParameters[:users] : []
    userIds.map! { |x| x.to_i }

    # Get list of users that should be displayed.    
    @usersToDisplay += User.where(:id => userIds)

    # Intersect the list with the list of users that are allowed to be displayed.
    @usersToDisplay = @usersToDisplay & @usersAllowedToDisplay 
    
  end
  

  def sanitizeDateParameter(parameter, default)

    if (parameter.respond_to?(:to_date)) then
      return parameter.to_date
    else
      return default
    end
  end
end
