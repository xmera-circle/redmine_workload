# frozen_string_literal: true

class WlUserVacationsController < ApplicationController
  include WlUserDataFinder

  helper :workloads

  before_action :authorize_global, only: %i[create update destroy]
  before_action :find_user_workload_data

  def index
    @is_allowed = User.current.allowed_to_globally?(:edit_user_vacations)
    @wl_user_vacations = User.current.wl_user_vacations
  end

  def new; end

  def edit
    @wl_user_vacation = begin
      WlUserVacation.find(params[:id])
    rescue StandardError
      nil
    end
  end

  def create
    @wl_user_vacation = WlUserVacation.new(wl_user_vacations_params)
    @wl_user_vacation.user_id = User.current.id

    respond_to do |format|
      if @wl_user_vacation.save
        format.html do
          flash[:notice] = l(:notice_user_vacation_saved)
          redirect_to(action: 'index', params: { year: params[:year] })
        end
      else
        format.html do
          render action: 'new'
        end
        format.api { render_validation_errors(@wl_user_vacation) }
      end
    end
  end

  def update
    @wl_user_vacation = begin
      WlUserVacation.find(params[:id])
    rescue StandardError
      nil
    end
    respond_to do |format|
      if @wl_user_vacation.update(wl_user_vacation_params)
        format.html do
          flash[:notice] = l(:notice_user_vacation_saved)
          redirect_to(action: 'index', params: { year: params[:year] })
        end
      else
        format.html do
          render action: 'edit'
        end
        format.xml { render xml: @wl_user_vacation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @wl_user_vacation = begin
      WlUserVacation.find(params[:id])
    rescue StandardError
      nil
    end
    @wl_user_vacation.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_user_vacation_deleted)
        redirect_to(action: 'index', params: { year: params[:year] })
      end
    end
  end

  private

  def wl_user_vacations_params
    params.require(:wl_user_vacations).permit(:user_id, :date_from, :date_to, :comments, :vacation_type)
  end

  def wl_user_vacation_params
    params.require(:wl_user_vacation).permit(:id, :user_id, :date_from, :date_to, :comments, :vacation_type)
  end
end
