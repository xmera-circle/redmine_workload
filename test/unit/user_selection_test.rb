# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WlUserSelectionTest < ActiveSupport::TestCase
    include WlUserDataDefaults

    fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
             :users, :issue_statuses, :enumerations, :roles

    def setup
      # Redmine >= 6.0 declares `fixtures :all` in its own test_helper, so every
      # fixture file is loaded regardless of what a test class asks for. Among
      # them is groups_users.yml, which makes users(:users_008) a member of two
      # groups. Queries for "all users belonging to any group" therefore no
      # longer return only the users generated below. Record what is already
      # there before adding anything.
      @fixture_group_member_ids =
        Group.all.flat_map { |group| group.users.select(&:active?) }.map(&:id).uniq

      @group1 = Group.generate!
      @group2 = Group.generate!
      @group3 = Group.generate!
      @user1 = User.generate!
      @user1.groups << @group1
      @user2 = User.generate!
      @user2.groups << @group2
      @user3 = User.generate!
      @user3.groups << @group3
      @group_member_ids = []
      @group_member_ids << @group1.users.map(&:id)
      @group_member_ids << @group2.users.map(&:id)
      @group_member_ids << @group3.users.map(&:id)
      @group_member_ids
    end

    ##
    # All users a global workload query may return: the ones generated in setup
    # plus the group members that come from Redmine's own fixtures.
    #
    def all_group_member_ids
      (@fixture_group_member_ids + @group_member_ids.flatten).uniq.sort
    end

    ##
    # Ids in the order WlUserSelection would render them.
    #
    def displayed_ids(current_user)
      groups = WlGroupSelection.new(user: current_user, groups: [@group1.id, @group2.id, @group3.id])
      WlUserSelection.new(user: current_user, group_selection: groups).allowed_to_display.map(&:id)
    end

    test 'should return all users if the current user is admin' do
      current_user = User.generate!(admin: true)
      groups = WlGroupSelection.new(user: current_user, groups: [@group1.id, @group2.id, @group3.id])
      users = WlUserSelection.new(user: current_user, group_selection: groups)
      assert_equal all_group_member_ids, users.allowed_to_display.map(&:id).sort
    end

    test 'should return all active users when user has permission :view_all_workloads' do
      current_user = users :users_002 # jsmith
      manager = roles :roles_001 # manager
      manager.add_permission! :view_all_workloads
      groups = WlGroupSelection.new(user: current_user, groups: [@group1.id, @group2.id, @group3.id])

      users = WlUserSelection.new(user: current_user, group_selection: groups)
      expected = all_group_member_ids
      current = users.send(:all_users).map(&:id).sort
      assert_equal expected, current
    end

    test 'should return users of the current users groups when allowed to :view_own_group_workloads' do
      current_user = users :users_002 # jsmith
      current_user.groups << @group1
      current_user.groups << @group3

      current_user.create_wl_user_data(default_attributes.merge(main_group: @group1.id))
      assert_equal @group1.id, current_user.wl_user_data.main_group

      manager = roles :roles_001 # manager
      manager.add_permission! :view_own_group_workloads
      groups = WlGroupSelection.new(user: current_user, groups: [@group1.id, @group2.id, @group3.id])

      users = WlUserSelection.new(user: current_user, group_selection: groups)
      expected = [@user1, @user3].map(&:id).sort
      current = users.allowed_to_display.map(&:id).sort
      assert_equal expected, current
    end

    test 'should order users by the display name format' do
      current_user = User.generate!(admin: true)
      zoe_adams = User.generate!(firstname: 'Zoe', lastname: 'Adams')
      adam_zimmer = User.generate!(firstname: 'Adam', lastname: 'Zimmer')
      [zoe_adams, adam_zimmer].each { |user| user.groups << @group1 }
      ids = [zoe_adams.id, adam_zimmer.id]

      # A new selection per block, otherwise User#name serves its memoized value
      # from before the setting changed.
      with_settings user_format: 'lastname_comma_firstname' do
        assert_equal [zoe_adams.id, adam_zimmer.id], displayed_ids(current_user) & ids
      end

      with_settings user_format: 'firstname_lastname' do
        assert_equal [adam_zimmer.id, zoe_adams.id], displayed_ids(current_user) & ids
      end
    end

    test 'should return the current user if allowed to :view_own_workloads' do
      current_user = users :users_002 # jsmith
      manager = roles :roles_001 # manager
      manager.add_permission! :view_own_workloads
      groups = WlGroupSelection.new(user: current_user, groups: [@group1.id, @group2.id, @group3.id])
      users = WlUserSelection.new(user: current_user, group_selection: groups)
      assert_equal [current_user.id], users.allowed_to_display.map(&:id)
    end

    test 'should return an empty array if the current user has no permission to view workloads' do
      current_user = User.anonymous
      groups = WlGroupSelection.new(user: current_user, groups: [@group1.id, @group2.id, @group3.id])
      users = WlUserSelection.new(user: current_user, group_selection: groups)

      assert_equal [], users.allowed_to_display
    end

    test 'should return current user if no other users given' do
      current_user = users :users_002 # jsmith
      manager = roles :roles_001 # manager
      manager.add_permission! :view_all_workloads
      groups = WlGroupSelection.new(user: current_user, groups: [])
      users = WlUserSelection.new(user: current_user, group_selection: groups)
      expected = [current_user]
      current = users.send(:include_current_user)
      assert_equal expected, current
    end

    test 'should not return current user if not selected' do
      @user1.create_wl_user_data(default_attributes.merge(main_group: @group1.id))
      current_user = users :users_002 # jsmith
      manager = roles :roles_001 # manager
      manager.add_permission! :view_all_workloads
      groups = WlGroupSelection.new(user: current_user, groups: [@group1.id, @group2.id, @group3.id])
      users = WlUserSelection.new(user: current_user, group_selection: groups)
      expected = []
      current = users.send(:include_current_user)
      assert_equal expected, current

      groups = WlGroupSelection.new(user: current_user, groups: [])
      users = WlUserSelection.new(user: current_user, users: [@user1.id, @user2.id, @user3.id], group_selection: groups)
      expected = []
      current = users.send(:include_current_user)
      assert_equal expected, current
    end
  end
end
