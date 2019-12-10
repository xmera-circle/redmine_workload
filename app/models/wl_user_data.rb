class WlUserData < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :threshold_lowload_min, :threshold_normalload_min, :threshold_highload_min
  self.table_name = "wl_user_datas"

end