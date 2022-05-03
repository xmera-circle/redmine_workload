# frozen_string_literal: true

##
# Presenter organising groups to be used in views/workloads/_filers.erb.
#
class GroupSelection
  ##
  # @param groups [Array(Group)] List of Group objects.
  # @param user [User] A user object.
  #
  # @note params[:user] is currently used for tests only!
  def initialize(**params)
    self.groups = params[:groups] || []
    self.user = define_user(params[:user])
  end

  ##
  # Returns selected groups when allowed to be viewed by the user.
  #
  # @return [Array(Group)] An array of group objects.
  def selected
    groups_by_params & allowed_to_display
  end

  ##
  # Prepares groups to be used as selection in filters.
  #
  def allowed_to_display
    groups_allowed_to_display.sort_by { |group| group[:lastname] }
  end

  def all_group_ids
    all_groups.map(&:id)
  end

  private

  attr_accessor :user, :groups

  ##
  # Define the current user.
  #
  def define_user(user)
    user || User.current
  end

  ##
  # Queries the groups the user is allowed to view.
  # @return [Array(Group)] List of group objects. The list is empty if the user
  #                        is not allowed to view any group.
  #
  def groups_allowed_to_display
    return all_groups if user.admin? || allowed_to?(:view_all_workloads)

    return own_groups if allowed_to?(:view_own_group_workloads)

    []
  end

  def all_groups
    Group.includes(users: :wl_user_data).distinct.all.to_a
  end

  def own_groups
    user.groups.to_a
  end

  def groups_by_params
    Group.joins(users: :wl_user_data).distinct.where(id: group_ids).to_a
  end

  def group_ids
    groups.map(&:to_i)
  end

  def allowed_to?(permission)
    user.allowed_to?(permission.to_sym, nil, global: true)
  end
end
