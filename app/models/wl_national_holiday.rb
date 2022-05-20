# frozen_string_literal: true

class WlNationalHoliday < ActiveRecord::Base
  unloadable

  validates :start, date: true
  validates :end,   date: true
  validates :start, :end, :reason, presence: true
  validate :check_datum

  after_destroy :clearCache
  after_save :clearCache

  def check_datum
    errors.add :end, :greater_than_start_date if workload_end_before_start?
  end

  private

  def workload_end_before_start?
    start && self.end && (start_changed? || end_changed?) && self.end < start
  end

  def clearCache
    Rails.cache.clear
  end
end
