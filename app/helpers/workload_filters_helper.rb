# frozen_string_literal: true

module WorkloadFiltersHelper
  def user_options_for_select(usersToShow, selectedUsers)
    result = ''

    usersToShow.each do |user|
      selected = selectedUsers.include?(user) ? 'selected="selected"' : ''

      result += "<option value=\"#{h(user.id)}\" #{selected}>#{h(user.name)}</option>"
    end

    result.html_safe
  end

  def group_options_for_select(groupsToShow, selectedGroups)
    result = ''

    groupsToShow.each do |group|
      selected = selectedGroups.include?(group) ? 'selected="selected"' : ''

      result += "<option value=\"#{h(group.id)}\" #{selected}>#{h(group.lastname)}</option>"
    end

    result.html_safe
  end
end
