# frozen_string_literal: true

class WlUserVacationsController < ApplicationController
  include WlUserDataFinder

  helper :workloads

  before_action :find_user_workload_data
  before_action :check_edit_rights, only: %i[edit update create destroy new]

  def index
    @is_allowed = User.current.allowed_to_globally?(:edit_user_vacations)
    @wl_user_vacation = WlUserVacation.where user_id: User.current
  end

  def new; end

  def edit
    @wl_user_vacation = begin
      WlUserVacation.find(params[:id])
    rescue StandardError
      nil
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
          flash[:notice] = l(:workload_user_vacation_saved)
          redirect_to(action: 'index', params: { year: params[:year] })
        end
      else
        format.html do
          render action: 'edit'
        end
        format.xml  { render xml: @wl_user_vacation.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @wl_user_vacation = WlUserVacation.new(wl_user_vacations_params)
    @wl_user_vacation.user_id = User.current.id

    respond_to do |format|
      if @wl_user_vacation.save
        format.html do
          flash[:notice] = l(:workload_user_vacation_saved)
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

  def destroy
    @wl_user_vacation = begin
      WlUserVacation.find(params[:id])
    rescue StandardError
      nil
    end
    @wl_user_vacation.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = l(:workload_user_vacation_deleted)
        redirect_to(action: 'index', params: { year: params[:year] })
      end
    end
  end

  private

  def check_edit_rights
    is_allowed = User.current.allowed_to_globally?(:edit_user_vacations)
    return if is_allowed

    flash[:error] = translate 'no_right'
    redirect_to action: 'index'
  end

  def wl_user_vacations_params
    params.require(:wl_user_vacations).permit(:user_id, :date_from, :date_to, :comments, :vacation_type)
  end

  def wl_user_vacation_params
    params.require(:wl_user_vacation).permit(:id, :user_id, :date_from, :date_to, :comments, :vacation_type)
  end
end
