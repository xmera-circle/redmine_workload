# frozen_string_literal: true

##
# Calculates day and user dependent workload threshold values
#
class WlDayCapacity
  ##
  # @param holiday [Boolean] Is either true or false.
  # @param assignee [User|Group|GroupUserDummy|String|Integer] Can handle several
  #                                                            objects but should
  #                                                            be User, Group or
  #                                                            GroupUserDummy.
  #
  def initialize(**params)
    self.holiday = params[:holiday]
    self.assignee = params[:assignee]
  end

  def threshold_at(key)
    return 0.0 if assignee == 'unassigned' || assignee.is_a?(Integer)

    holiday? ? 0.0 : user.send("threshold_#{key}_min")
  end

  private

  attr_accessor :holiday, :assignee

  def user
    return GroupUserDummy.new(group: assignee) unless assignee.is_a? User

    # returns default thresholds when a user has no custom values
    assignee.wl_user_data || WlDefaultUserData.new
  end

  def holiday?
    holiday
  end
end
