# frozen_string_literal: true

##
# Provides some helper methods for WlUserData related forms.
#
module WlUserDatasHelper
  ##
  # The user's groups, without those excluded from workload planning. The
  # group currently set as main group is always offered, even if excluded --
  # otherwise the select would silently fall back to its first entry and the
  # main group would change on the next save without anyone choosing it.
  #
  def user_groups_for_select(selected:)
    groups = RedmineWorkload::WlGroupExclusion.reject_excluded(WlUserData.own_groups.to_a)
    current = WlUserData.own_groups.find_by(id: selected)
    groups |= [current] if current
    options_for_select(groups.map { |group| [group.lastname, group.id] }, selected)
  end
end
