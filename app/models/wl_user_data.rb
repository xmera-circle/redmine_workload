# frozen_string_literal: true

##
# Holds user related data for workload calculation.
#
class WlUserData < ActiveRecord::Base
  belongs_to :user, inverse_of: :wl_user_data, optional: true
  self.table_name = 'wl_user_datas'

  validates :threshold_lowload_min, :threshold_normalload_min, :threshold_highload_min, presence: true
  validate :selected_group

  def self.own_groups(user_object = User.current)
    user_object.groups
  end

  def update_to_defaults_when_new
    return unless new_record?

    update(default_attributes)
  end

  private

  def selected_group
    return if main_group.blank? || own_group?(user)

    errors.add(:main_group, :inclusion)
  end

  def own_group?(user)
    self.class.own_groups(user).pluck(:id).include? main_group
  end

  def default_attributes
    { threshold_lowload_min: settings['threshold_lowload_min'],
      threshold_normalload_min: settings['threshold_normalload_min'],
      threshold_highload_min: settings['threshold_highload_min'] }
  end

  def settings
    Setting['plugin_redmine_workload']
  end
end
