# frozen_string_literal: true

class WlUserData < ActiveRecord::Base
  belongs_to :user

  validates :threshold_lowload_min, :threshold_normalload_min, :threshold_highload_min, presence: true
  self.table_name = 'wl_user_datas'
end
