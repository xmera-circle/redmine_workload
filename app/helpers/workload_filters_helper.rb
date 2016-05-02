# -*- encoding : utf-8 -*-
module WorkloadFiltersHelper
  def get_option_tags_for_userselection(usersToShow, selectedUsers)

    result = '';

    usersToShow.each do |user|
      selected = selectedUsers.include?(user) ? 'selected="selected"' : ''

      result += "<option value=\"#{h(user.id)}\" #{selected}>#{h(user.name)}</option>"
    end

    return result.html_safe
  end

  def get_option_tags_for_groupselection(groupsToShow, selectedGroups)
    
    result = '';

    groupsToShow.each do |group|            
      
      selected = selectedGroups.include?(group) ? 'selected="selected"' : ''

     result += "<option value=\"#{h(group.id)}\" #{selected}>#{h(group.lastname)}</option>"
    
    end
    

    return result.html_safe
  end  
end
