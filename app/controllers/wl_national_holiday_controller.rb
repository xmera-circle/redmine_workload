# frozen_string_literal: true

require 'json'

class WlNationalHolidayController < ApplicationController
  include RedmineWorkload::WlUserDataFinder

  before_action :authorize_global, only: %i[create update destroy]
  before_action :find_user_workload_data
  before_action :select_year

  helper :workloads

  def index
    filter_year_start = Date.new(@this_year, 0o1, 0o1)
    filter_year_end = Date.new(@this_year, 12, 31)
    @wl_national_holiday = WlNationalHoliday.where('start between ? AND ?', filter_year_start, filter_year_end)
    @is_allowed = User.current.allowed_to_globally?(:edit_national_holiday)
  end

  def new; end

  def edit
    @wl_national_holiday = begin
      WlNationalHoliday.find(params[:id])
    rescue StandardError
      nil
    end
  end

  def create
    @wl_national_holiday = WlNationalHoliday.new(wl_national_holiday_params)
    if @wl_national_holiday.save
      flash[:notice] = l(:notice_holiday_saved)
      redirect_to action: 'index', year: params[:year]
    else
      respond_to do |format|
        format.html do
          render :new
        end
        format.api { render_validation_errors(@wl_national_holiday) }
      end
    end
  end

  def update
    @wl_national_holiday = begin
      WlNationalHoliday.find(params[:id])
    rescue StandardError
      nil
    end

    respond_to do |format|
      if @wl_national_holiday.update(wl_national_holiday_params)
        format.html do
          flash[:notice] = l(:notice_holiday_updated)
          redirect_to(action: 'index', params: { year: params[:year] })
        end
        format.xml  { head :ok }
      else
        format.html do
          render action: 'edit'
        end
        format.xml { render xml: @wl_national_holiday.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @wl_national_holiday = begin
      WlNationalHoliday.find(params[:id])
    rescue StandardError
      nil
    end
    @wl_national_holiday.destroy
    flash[:notice] = l(:notice_holiday_deleted)
    redirect_to(action: 'index', year: params[:year])
  end

  private

  def select_year
    if params[:year]
      @this_year = params[:year].to_i
    elsif @this_year.blank?
      @this_year = Time.zone.today.strftime('%Y').to_i
    end
  end

  def wl_national_holiday_params
    params.require(:wl_national_holiday).permit(:start, :end, :reason)
  end
end
