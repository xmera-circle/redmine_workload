# frozen_string_literal: true

##
# Holds default user related data for workload calculation.
#
class WlDefaultUserData
  include RedmineWorkload::WlUserDataDefaults

  def threshold_lowload_min
    default_attributes[:threshold_lowload_min].to_f
  end

  def threshold_normalload_min
    default_attributes[:threshold_normalload_min].to_f
  end

  def threshold_highload_min
    default_attributes[:threshold_highload_min].to_f
  end
end
