# frozen_string_literal: true

##
# Presenter organising users to be used in views/workloads/_filers.erb.
#
class UserSelection
  attr_reader :groups

  ##
  # @param users [User] Selected user objects.
  # @param groups [GroupSelection] GroupSelection object.
  #
  def initialize(**params)
    self.user = params[:user] || User.current
    self.users = params[:users] || []
    self.groups = params[:group_selection]
    self.selected_groups = groups.selected
  end

  def all
    selected_groups | selected
  end

  ##
  # Returns selected users when allowed to be viewed by the given user.
  #
  # @return [Array(User)] An array of user objects.
  def selected
    (users_from_context & allowed_to_display) | [user]
  end

  ##
  # Prepares users to be used in filters
  # @return [Array(User)] An array of user objects.
  def allowed_to_display
    users_allowed_to_display.sort_by(&:lastname)
  end

  private

  attr_accessor :user, :users, :selected_groups
  attr_writer :groups

  ##
  # If groups are given the method will query those users having one of the given
  # groups as main group. If no groups are given the users_by_params will be
  # returned instead.
  #
  # @return [Array(User)] An array of user objects.
  #
  def users_from_context
    selected_users = users_of_groups | users_by_params
    return users_by_params if groups.selected.blank?

    selected_users.select(&:wl_user_data)
  end

  ##
  # Collects all users across all projects where the given user has the permission
  # to view the project workload.
  #
  # @param [User] An optional single user object. Default: User.current.
  # @return [Array(User)] Array of all users objects the current user may display.
  #
  def users_allowed_to_display
    return all_users if user.admin? || allowed_to?(:view_all_workloads)

    result = group_members_allowed_to(:view_own_group_workloads)

    if result.blank?
      result = allowed_to?(:view_own_workloads) ? [user] : []
    end

    result.flatten.uniq
  end

  def all_users
    all = User.joins(:groups).distinct
    return all.joins(:wl_user_data).active if selected_groups.present?

    all.active
  end

  ##
  # Get all active users of groups where the current user has a membership.
  #
  # @param permission [String|Symbol] Permission name.
  # @return [Array(User)] An array of user objects.
  #
  def group_members_allowed_to(permission)
    return [] unless allowed_to?(permission)

    user.groups.map(&:users)
  end

  ##
  # Queries all active users as given by workload params.
  #
  # @return [Array(User)] An array of user objects.
  def users_by_params
    all_users.where(id: user_ids).to_a
  end

  ##
  # Collects all users belonging to selected groups.
  #
  # @return [Array(User)] An array of user objects.
  #
  def users_of_groups
    result = selected_groups.map { |group| group.users.to_a }.flatten
    result.uniq
  end

  def user_ids
    users.map(&:to_i)
  end

  def allowed_to?(permission)
    user.allowed_to?(permission.to_sym, nil, global: true)
  end
end
