# frozen_string_literal: true

module WorkloadFiltersHelper
  def user_options_for_select(users_to_show, selected_users)
    result = ''
    return unless users_to_show

    users_to_show.each do |user|
      selected = selected_users.include?(user) ? 'selected="selected"' : ''

      result += "<option value=\"#{h(user.id)}\" #{selected}>#{h(user.name)}</option>"
    end

    result.html_safe
  end

  def group_options_for_select(groups_to_show, selected_groups)
    result = ''
    return unless groups_to_show

    groups_to_show.each do |group|
      selected = selected_groups.include?(group) ? 'selected="selected"' : ''

      result += "<option value=\"#{h(group&.id)}\" #{selected}>#{h(group.lastname)}</option>"
    end

    result.html_safe
  end
end
