# frozen_string_literal: true

class WlUserDatasController < ApplicationController
  helper :work_load

  before_action :check_edit_rights, only: [:create_update]

  def show
    @is_allowed = User.current.allowed_to_globally?(:edit_user_data)

    @user_workload_data = WlUserData.find_by user_id: User.current.id
    if @user_workload_data.nil?
      data = WlUserData.new
      data.user_id = User.current.id
      data.threshold_lowload_min    = Setting['plugin_redmine_workload']['threshold_lowload_min']
      data.threshold_normalload_min = Setting['plugin_redmine_workload']['threshold_normalload_min']
      data.threshold_highload_min   = Setting['plugin_redmine_workload']['threshold_highload_min']
      @user_workload_data = data
    end
  end

  def create_update
    @user_workload_data = WlUserData.find_or_initialize_by user_id: User.current.id

    logger.info "Parameter sind: #{params.inspect}"

    respond_to do |format|
      if @user_workload_data.update(wl_user_data_params)
        format.html do
          flash[:notice] = l(:notice_account_updated)
          redirect_to(action: 'show')
        end
        format.xml { head :ok }
      else
        format.html do
          flash[:error] = '<ul>' + @user_workload_data.errors.full_messages.map do |o|
                                     "<li>#{o}</li>"
                                   end.join + '</ul>'
          redirect_to(action: 'show')
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
