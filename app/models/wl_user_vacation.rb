class WlUserVacation < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  
  attr_accessible :user_id  
  attr_accessible :date_from
  attr_accessible :date_to
  attr_accessible :comments
  attr_accessible :vacation_type
  validates :date_from, :date => true
  validates :date_to, :date => true
  
  validates_presence_of :date_from, :date_to
  validate :check_datum
  
  after_save :clearCache
  after_destroy :clearCache  
  
  def check_datum
    if self.date_from && self.date_to && (date_from_changed? || date_to_changed?) && self.date_to < self.date_from
       errors.add :date_to, :workload_end_before_start 
    end 
  end
  
private
  def clearCache
    Rails.cache.clear
  end
end