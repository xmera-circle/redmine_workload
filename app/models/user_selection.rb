# frozen_string_literal: true

##
# Presenter organising users to be used in views/workloads/_filers.erb.
#
class UserSelection
  def initialize(**params)
    self.user = params[:user] || User.current
    self.users = params[:users] || []
    self.selected_groups = params[:selected_groups] || []
  end

  ##
  # Prepares users to be used in filters
  # @return [Array(User)] An array of user objects.
  def to_display
    (users_of_groups | users_by_params) & allowed_to_display
  end

  ##
  # Prepares users to be used in filters
  # @return [Array(User)] An array of user objects.
  def allowed_to_display
    users_allowed_to_display.sort_by { |user| user[:lastname] }
  end

  private

  attr_accessor :user, :users, :selected_groups

  ##
  # Collects all users across all projects where the given user has the permission
  # to view the project workload.
  #
  # @param [User] An optional single user object. Default: User.current.
  # @return [Array(User)] Array of all users objects the current user may display.
  #
  def users_allowed_to_display
    return [] if user.anonymous?
    return User.active.to_a if user.admin?

    result = project_members_allowed_to(:view_project_workload)
    result << user
    result.uniq
  end

  ##
  # Get all members of projects where the user has the
  # given permission.
  # @param permission [String|Symbol] Permission name.
  # @return [Array(User)] An array of user objects.
  #
  def project_members_allowed_to(permission)
    Project.allowed_to(user, permission.to_sym).map do |project|
      project.members.map(&:user)
    end.flatten
  end

  ##
  # Queries all users as given by workload params.
  #
  # @return [Array(User)] An array of user objects.
  def users_by_params
    User.where(id: user_ids).to_a
  end

  ##
  # Collects all users belonging to selected groups.
  #
  # @return [Array(User)] An array of user objects.
  #
  def users_of_groups
    result = selected_groups.map { |group| group.users.to_a }.flatten
    result << user
    result.uniq
  end

  def user_ids
    users.map(&:to_i)
  end
end
