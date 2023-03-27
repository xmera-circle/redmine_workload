# frozen_string_literal: true

class WlUserDatasController < ApplicationController
  include RedmineWorkload::WlUserDataFinder

  helper :workloads
  helper :wl_user_datas

  before_action :authorize_global, only: %i[update]
  before_action :find_user_workload_data, only: %i[edit update]

  def edit
    @is_allowed = User.current.allowed_to_globally?(:edit_user_data)
  end

  def update
    respond_to do |format|
      if @user_workload_data.update(wl_user_data_params)
        format.html do
          flash[:notice] = l(:notice_settings_updated)
          redirect_to workloads_path
        end
        format.xml { head :ok }
      else
        format.html do
          render :edit
        end
        format.xml { render xml: @user_workload_data.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def wl_user_data_params
    params.require(:wl_user_data).permit(:user_id, :threshold_lowload_min, :threshold_normalload_min,
                                         :threshold_highload_min, :main_group)
  end
end
