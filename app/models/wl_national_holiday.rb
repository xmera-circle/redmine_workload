# frozen_string_literal: true

class WlNationalHoliday < ActiveRecord::Base
  validates :start, date: true
  validates :end,   date: true
  validates :start, :end, :reason, presence: true
  validate :check_datum

  after_destroy :clear_cache
  after_save :clear_cache

  def check_datum
    errors.add :end, :greater_than_start_date if workload_end_before_start?
  end

  private

  def workload_end_before_start?
    start && self.end && (start_changed? || end_changed?) && self.end < start
  end

  def clear_cache
    Rails.cache.clear
  end
end
