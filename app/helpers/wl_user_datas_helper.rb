# frozen_string_literal: true

##
# Provides some helper methods for WlUserData related forms.
#
module WlUserDatasHelper
  def user_groups_for_select(selected:)
    options = []
    options += WlUserData.own_groups.pluck(:lastname, :id)
    options_for_select(options, selected)
  end
end
