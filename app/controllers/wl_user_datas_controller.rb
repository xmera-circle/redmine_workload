# frozen_string_literal: true

class WlUserDatasController < ApplicationController
  include WlUserDataFinder

  helper :workloads

  before_action :check_edit_rights, only: [:update]
  before_action :find_user_workload_data, only: %i[edit update]

  def edit
    @is_allowed = User.current.allowed_to_globally?(:edit_user_data)
  end

  def update
    respond_to do |format|
      if @user_workload_data.update(wl_user_data_params)
        format.html do
          flash[:notice] = l(:notice_account_updated)
          redirect_to workloads_index_path
        end
        format.xml { head :ok }
      else
        format.html do
          flash[:error] = '<ul>' + @user_workload_data.errors.full_messages.map do |o|
                                     "<li>#{o}</li>"
                                   end.join + '</ul>'
          render :edit
        end
        format.xml { render xml: @user_workload_data.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def check_edit_rights
    is_allowed = User.current.allowed_to_globally?(:edit_user_data)
    unless is_allowed
      flash[:error] = translate 'no_right'
      redirect_to :back
    end
  end

  def wl_user_data_params
    params.require(:wl_user_data).permit(:user_id, :threshold_lowload_min, :threshold_normalload_min,
                                         :threshold_highload_min)
  end
end
