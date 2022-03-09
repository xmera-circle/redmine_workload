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
    if start && self.end && (start_changed? || end_changed?) && self.end < start
      errors.add :end, :workload_end_before_start
    end
  end

  private

  def clearCache
    Rails.cache.clear
  end
end
