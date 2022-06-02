# frozen_string_literal: true

##
# Calculates day and user dependent workload threshold values
#
class WlDayCapacity
  ##
  # @param assignee [User|Group|GroupUserDummy|String|Integer] Can handle several
  #                                                            objects but should
  #                                                            be User, Group or
  #                                                            GroupUserDummy.
  #
  def initialize(**params)
    self.assignee = params[:assignee]
  end

  def threshold_at(key, holiday)
    return 0.0 if assignee == 'unassigned' || assignee.is_a?(Integer)

    holiday ? 0.0 : user.send("threshold_#{key}_min")
  end

  private

  attr_accessor :assignee

  ##
  # Check what kind of assignee should be used.
  #
  def user
    @user ||= assignee.is_a?(User) ? assignee.wl_user_data || WlDefaultUserData.new : GroupUserDummy.new(group: assignee)
  end
end
