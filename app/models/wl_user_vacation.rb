# frozen_string_literal: true

class WlUserVacation < ActiveRecord::Base
  belongs_to :user, inverse_of: :wl_user_vacations, optional: true

  validates :date_from, date: true
  validates :date_to, date: true

  validates :date_from, :date_to, presence: true
  validate :check_datum

  after_destroy :clear_cache
  after_save :clear_cache

  def check_datum
    errors.add :date_to, :greater_than_start_date if workload_end_before_start?
  end

  private

  def workload_end_before_start?
    date_from && date_to && (date_from_changed? || date_to_changed?) && date_to < date_from
  end

  def clear_cache
    Rails.cache.clear
  end
end
