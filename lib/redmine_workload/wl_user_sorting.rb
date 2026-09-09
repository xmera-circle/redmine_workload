# frozen_string_literal: true

module RedmineWorkload
  ##
  # Ordering of users and group dummies in the workload views.
  #
  # Redmine renders a user's name according to the 'Users display format'
  # setting, so the list has to be ordered by that name rather than by the
  # last name. Otherwise an installation using 'Firstname Lastname' shows an
  # apparently unsorted list.
  #
  module WlUserSorting
    ##
    # @param user [User|GroupUserDummy] Object responding to name and id.
    # @return [Array] Sort key following Setting.user_format.
    #
    def user_sort_key(user)
      [user.name.to_s.downcase, user.id.to_i]
    end
  end
end
