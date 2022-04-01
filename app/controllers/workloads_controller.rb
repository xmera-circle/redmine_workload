# frozen_string_literal: true

class WorkloadsController < ApplicationController
  unloadable

  helper :gantt
  helper :issues
  helper :projects
  helper :queries
  helper :workload_filters

  include QueriesHelper
  include WlUserDataFinder

  before_action :authorize_global, only: %i[index]
  before_action :find_user_workload_data

  def index
    workload_params = params[:workload] || {}

    @first_day = sanitizeDateParameter(workload_params[:first_day],  Time.zone.today - 10)
    @last_day  = sanitizeDateParameter(workload_params[:last_day],   Time.zone.today + 50)
    @today     = sanitizeDateParameter(workload_params[:start_date], Time.zone.today)

    # if @today ("select as today") is before @first_day take @today as @first_day
    @first_day = [@today, @first_day].min

    # Make sure that last_day is at most 12 months after first_day to prevent
    # long running times
    @last_day = [(@first_day >> 12) - 1, @last_day].min
    @time_span_to_display = @first_day..@last_day

    @groups = GroupSelection.new(groups: workload_params[:groups])
    @users = UserSelection.new(users: workload_params[:users], group_selection: @groups)

    assignees = @groups.selected.presence ? (@groups.selected | @users.selected) : @users.selected
    @issues_for_workload = ListUser.open_issues_for_users(assignees)

    @months_to_render = DateTools.months_in_time_span(@time_span_to_display)
    @workloadData   = ListUser.hours_per_user_issue_and_day(@issues_for_workload, @time_span_to_display, @today)
    @group_workload = GroupWorkload.new(user_workload: @workloadData,
                                        selected_groups: @groups.selected,
                                        time_span: @time_span_to_display)
  end

  private

  def sanitizeDateParameter(parameter, default)
    if parameter.respond_to?(:to_date)
      parameter.to_date
    else
      default
    end
  end
end
