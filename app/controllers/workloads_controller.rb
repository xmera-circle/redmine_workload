# frozen_string_literal: true

class WorkloadsController < ApplicationController
  unloadable

  helper :gantt
  helper :issues
  helper :projects
  helper :queries
  helper :workload_filters
  helper :workloads

  include QueriesHelper
  include RedmineWorkload::WlUserDataFinder
  include WorkloadsHelper

  before_action :authorize_global, only: %i[index]
  before_action :find_user_workload_data
  before_action :valid_encoding?, only: %i[index]

  accept_api_auth :index

  def index
    @first_day = sanitizeDateParameter(workload_params[:first_day],  Time.zone.today - 10)
    @last_day  = sanitizeDateParameter(workload_params[:last_day],   Time.zone.today + 50)
    @today     = sanitizeDateParameter(workload_params[:start_date], Time.zone.today)
    @date_check = @last_day >= @first_day

    # if @today ("select as today") is before @first_day take @today as @first_day
    @first_day = [@today, @first_day].min

    # Make sure that last_day is at most 12 months after first_day to prevent
    # long running times
    @last_day = [(@first_day >> 12) - 1, @last_day].min
    @time_span_to_display = @first_day..@last_day

    if @date_check
      @groups = WlGroupSelection.new(groups: workload_params[:groups])
      @users = WlUserSelection.new(users: workload_params[:users], group_selection: @groups)

      assignees = @users.all_selected
      user_workload = UserWorkload.new(assignees: assignees,
                                       time_span: @time_span_to_display,
                                       today: @today)

      @months_to_render = RedmineWorkload::WlDateTools.months_in_time_span(@time_span_to_display)
      @workload_data = user_workload.hours_per_user_issue_and_day

      @group_workload = GroupWorkload.new(users: @users,
                                          user_workload: @workload_data,
                                          time_span: @time_span_to_display)

      @workload = groups?(@groups) ? @group_workload : user_workload
    end

    respond_to do |format|
      format.html do
        flash.now[:error] = l(:error_date_setting) unless @date_check
        render action: :index
      end

      format.csv do
        send_data(workloads_to_csv(@workload, params),
                  type: 'text/csv; header=present',
                  filename: 'workload.csv')
      end
    end
  end

  private

  def valid_encoding?
    return index unless params[:encoding]

    valid = encoding_options.any? { |option| params[:encoding].casecmp(option).zero? }
    return index if valid

    flash.now[:error] = l(:error_encoding_setting, encoding_options.join(', '))
    params[:encoding] = nil
    index
  end

  def encoding_options
    utf8 = %w[UTF-8 UTF8]
    general_csv_encoding = [l(:general_csv_encoding), l(:general_csv_encoding).delete('-')]
    if general_csv_encoding.all? { |encoding| encoding.casecmp('UTF-8').zero? }
      utf8
    else
      [general_csv_encoding, utf8].flatten
    end
  end

  ##
  # Prepares workload params based on params[:workload] and params[:filter_type]
  # where the latter is relevant for exporting the data via csv.
  #
  def workload_params
    wl_params = params[:workload]&.merge(filter_type: params[:filter_type]) || {}
    return wl_params if wl_params[:filter_type].blank?

    wl_params.merge(assignee_ids)
  end

  def assignee_ids
    filter = params[:filter_type]&.first
    return if filter.blank?

    groups = filter.include? 'groups'
    groups ? { groups: WlGroupSelection.new.all_group_ids } : { users: WlUserSelection.new.all_user_ids }
  end

  def sanitizeDateParameter(parameter, default)
    if parameter.respond_to?(:to_date)
      parameter.to_date
    else
      default
    end
  end
end
