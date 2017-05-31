class WlNationalHoliday < ActiveRecord::Base
  unloadable
  attr_accessible :start
  attr_accessible :end
  attr_accessible :reason
  validates :start, :date => true
  validates :end,   :date => true
  validates_presence_of :start, :end, :reason
  validate :check_datum
  
  after_save :clearCache
  after_destroy :clearCache
  
  def check_datum
    if self.start && self.end && (start_changed? || end_changed?) && self.end < self.start 
       errors.add :end, :workload_end_before_start 
    end 
  end
  
  private
  def clearCache
    Rails.cache.clear
  end
end
