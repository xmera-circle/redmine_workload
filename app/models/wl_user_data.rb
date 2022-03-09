# frozen_string_literal: true

class WlUserData < ActiveRecord::Base
  belongs_to :user

  validates :threshold_lowload_min, :threshold_normalload_min, :threshold_highload_min, presence: true
  self.table_name = 'wl_user_datas'

  def update_to_defaults_when_new
    return unless new_record?

    update(default_attributes)
  end

  private

  def default_attributes
    { threshold_lowload_min: settings['threshold_lowload_min'],
      threshold_normalload_min: settings['threshold_normalload_min'],
      threshold_highload_min: settings['threshold_highload_min'] }
  end

  def settings
    Setting['plugin_redmine_workload']
  end
end
