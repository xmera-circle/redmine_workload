# frozen_string_literal: true

##
# Finder method for WLUserData
#
module WlUserDataFinder
  ##
  # Finds the workload data of the current user or creates them if not found.
  # When @user_workload_data is a new record default values will be assigned.
  #
  def find_user_workload_data
    @user_workload_data = WlUserData.find_or_create_by(user_id: User.current.id)
    @user_workload_data.update_to_defaults_when_new
  end
end
