# -*- encoding : utf-8 -*-
module FiltersHelper
  def get_option_tags_for_userselection(usersToShow, selectedUsers)

    result = '';

    usersToShow.each do |user|
      selected = selectedUsers.include?(user) ? 'selected="selected"' : ''

      result += "<option value=\"#{h(user.id)}\" #{selected}>#{h(user.firstname)} #{h(user.lastname)} (#{h(user.name)})</option>"
    end

    return result.html_safe
  end
end
