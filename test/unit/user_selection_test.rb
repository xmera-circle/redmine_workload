# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class UserSelectionTest < ActiveSupport::TestCase
  fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
           :users, :issue_statuses, :enumerations, :roles

  test 'should return all users if the current user is admin' do
    user = User.generate!(admin: true)
    users = UserSelection.new(user: user)

    assert_equal User.active.map(&:id).sort, users.allowed_to_display.map(&:id).sort
  end

  test 'should return all active users when user has permission :view_all_workloads' do
    current_user = users :users_002 # jsmith
    manager = roles :roles_001 # manager
    manager.add_permission! :view_all_workloads
    users = UserSelection.new(user: current_user)
    expected = User.active.pluck(:id).sort
    current = users.allowed_to_display.map(&:id).sort
    assert_equal expected, current
  end

  test 'should return users of the current users groups when allowed to :view_own_group_workloads' do
    group1 = Group.generate!
    group2 = Group.generate!
    group3 = Group.generate!
    user1 = User.generate!
    user1.groups << group1
    user2 = User.generate!
    user2.groups << group2
    user3 = User.generate!
    user3.groups << group3

    current_user = users :users_002 # jsmith
    current_user.groups << group1
    current_user.groups << group3
    manager = roles :roles_001 # manager
    manager.add_permission! :view_own_group_workloads

    users = UserSelection.new(user: current_user)
    expected = [current_user, user1, user3].map(&:id).sort
    current = users.allowed_to_display.map(&:id).sort
    assert_equal expected, current
  end

  test 'should return the current user if allowed to :view_own_workloads' do
    current_user = users :users_002 # jsmith
    manager = roles :roles_001 # manager
    manager.add_permission! :view_own_workloads
    users = UserSelection.new(user: current_user)
    assert_equal [current_user.id], users.allowed_to_display.map(&:id)
  end

  test 'should return an empty array if the current user has no permission to view workloads' do
    users = UserSelection.new(user: User.anonymous)

    assert_equal [], users.allowed_to_display
  end
end
