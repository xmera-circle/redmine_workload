# frozen_string_literal: true

##
# Administrators mark here which groups stay out of the workload group filter.
#
# The page writes the same custom field value that is shown on each group's
# form; it is a collected view of it, not a separate setting.
#
class WlGroupSettingsController < ApplicationController
  layout 'admin'
  self.main_menu = false

  before_action :require_admin

  def index
    @custom_field = RedmineWorkload::WlGroupExclusion.custom_field
    @groups = Group.givable.sorted
    @excluded_ids = RedmineWorkload::WlGroupExclusion.excluded_group_ids
  end

  def update
    field = RedmineWorkload::WlGroupExclusion.custom_field
    if field.nil?
      flash[:error] = l(:text_workload_group_field_missing)
      return redirect_to(wl_group_settings_path)
    end

    wanted = Array(params[:excluded_group_ids]).map(&:to_i)
    current = RedmineWorkload::WlGroupExclusion.excluded_group_ids

    Group.givable.find_each do |group|
      exclude = wanted.include?(group.id)
      next if exclude == current.include?(group.id)

      group.custom_field_values = { field.id.to_s => (exclude ? '1' : '0') }
      group.save
    end

    flash[:notice] = l(:notice_successful_update)
    redirect_to wl_group_settings_path
  end

  ##
  # Recreates the custom field after an administrator deleted it by hand.
  #
  def create_custom_field
    RedmineWorkload::WlGroupExclusion.ensure_custom_field!
    flash[:notice] = l(:notice_successful_create)
    redirect_to wl_group_settings_path
  end
end
