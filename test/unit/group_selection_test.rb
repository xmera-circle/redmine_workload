# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WlGroupSelectionTest < ActiveSupport::TestCase
    fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
            :users, :issue_statuses, :enumerations, :roles

    def setup
      Group.where.not(id: [12, 13]).delete_all
      @build_in_groups = Group.where(id: [12, 13])
      @groups = 5.times.map { |count| Group.generate! if count }
    end

    test 'should return all groups if the current user is admin' do
      admin = users :users_001 # admin
      groups = WlGroupSelection.new(user: admin)
      expected = (@groups.map(&:id) | @build_in_groups.map(&:id)).uniq.sort
      current = groups.allowed_to_display.map(&:id).sort
      assert_equal expected, current
    end

    test 'should return all groups when user has permission :view_all_workloads' do
      current_user = users :users_002 # jsmith
      manager = roles :roles_001 # manager
      manager.add_permission! :view_all_workloads
      groups = WlGroupSelection.new(user: current_user)
      expected = (@groups.map(&:id) | @build_in_groups.map(&:id)).uniq.sort
      current = groups.allowed_to_display.map(&:id).sort
      assert_equal expected, current
    end

    test 'should return current users groups when allowed to :view_own_group_workloads' do
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
      current_user.groups << [group1, group3]
      manager = roles :roles_001 # manager
      manager.add_permission! :view_own_group_workloads
      groups = WlGroupSelection.new(user: current_user)
      expected = [group1, group3].map(&:id).sort
      current = groups.allowed_to_display.map(&:id).sort
      assert_equal expected, current
    end

    test 'should return an empty array if the current user has no permission to view workloads' do
      groups = WlGroupSelection.new(user: User.anonymous)

      assert_equal [], groups.allowed_to_display
    end
  end
end
