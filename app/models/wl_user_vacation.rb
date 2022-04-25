# frozen_string_literal: true

class WlUserVacation < ActiveRecord::Base
  unloadable

  belongs_to :user, inverse_of: :wl_user_data, optional: true

  validates :date_from, date: true
  validates :date_to, date: true

  validates :date_from, :date_to, presence: true
  validate :check_datum

  after_destroy :clearCache
  after_save :clearCache

  def check_datum
    errors.add :date_to, :workload_end_before_start if workload_end_before_start?
  end

  private

  def workload_end_before_start?
    date_from && date_to && (date_from_changed? || date_to_changed?) && date_to < date_from
  end

  def clearCache
    Rails.cache.clear
  end
end
