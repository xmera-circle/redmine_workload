# frozen_string_literal: true

##
# Adds main_group column to store the users group which should be considered when
# calculating group workloads.
#
class AddMainGroupToWlUserData < ActiveRecord::Migration[5.2]
  def change
    add_column :wl_user_datas, :main_group, :integer
    add_index :wl_user_datas, :main_group
  end
end
