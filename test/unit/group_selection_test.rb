# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WlGroupSelectionTest < ActiveSupport::TestCase
    fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
             :users, :issue_statuses, :enumerations, :roles

    def setup
      Group.where.not(id: [12, 13]).delete_all
      # 12 and 13 are the built-in pseudo groups (non member, anonymous). They
      # must never show up in the filter.
      @built_in_groups = Group.where(id: [12, 13])
      @groups = 5.times.map { |count| Group.generate! if count }
    end

    test 'should return all groups if the current user is admin' do
      admin = users :users_001 # admin
      groups = WlGroupSelection.new(user: admin)
      expected = @groups.map(&:id).sort
      current = groups.allowed_to_display.map(&:id).sort
      assert_equal expected, current
    end

    test 'should return all groups when user has permission :view_all_workloads' do
      current_user = users :users_002 # jsmith
      manager = roles :roles_001 # manager
      manager.add_permission! :view_all_workloads
      groups = WlGroupSelection.new(user: current_user)
      expected = @groups.map(&:id).sort
      current = groups.allowed_to_display.map(&:id).sort
      assert_equal expected, current
    end

    test 'should never return the built-in groups' do
      admin = users :users_001 # admin
      groups = WlGroupSelection.new(user: admin)
      assert_empty groups.allowed_to_display.map(&:id) & @built_in_groups.map(&:id)
      assert_empty groups.all_group_ids & @built_in_groups.map(&:id)
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

    test 'should leave out groups marked as excluded' do
      field = RedmineWorkload::WlGroupExclusion.ensure_custom_field!
      excluded = @groups.first
      excluded.custom_field_values = { field.id.to_s => '1' }
      excluded.save!

      admin = users :users_001 # admin
      groups = WlGroupSelection.new(user: admin)

      assert_not_includes groups.allowed_to_display.map(&:id), excluded.id
      assert_not_includes groups.all_group_ids, excluded.id
      assert_equal @groups.size - 1, groups.allowed_to_display.size
    end

    test 'should apply the exclusion to a users own groups as well' do
      field = RedmineWorkload::WlGroupExclusion.ensure_custom_field!
      visible = Group.generate!
      hidden = Group.generate!
      hidden.custom_field_values = { field.id.to_s => '1' }
      hidden.save!

      current_user = users :users_002 # jsmith
      current_user.groups << [visible, hidden]
      manager = roles :roles_001 # manager
      manager.add_permission! :view_own_group_workloads

      groups = WlGroupSelection.new(user: current_user)
      assert_equal [visible.id], groups.allowed_to_display.map(&:id)
    end

    test 'should not select an excluded group even when asked for by id' do
      field = RedmineWorkload::WlGroupExclusion.ensure_custom_field!
      excluded = @groups.first
      excluded.custom_field_values = { field.id.to_s => '1' }
      excluded.save!

      admin = users :users_001 # admin
      groups = WlGroupSelection.new(user: admin, groups: [excluded.id])
      assert_empty groups.selected
    end

    test 'should exclude nothing when the custom field is missing' do
      RedmineWorkload::WlGroupExclusion.ensure_custom_field!.destroy

      admin = users :users_001 # admin
      groups = WlGroupSelection.new(user: admin)
      assert_equal @groups.map(&:id).sort, groups.allowed_to_display.map(&:id).sort
    end

    test 'should return an empty array if the current user has no permission to view workloads' do
      groups = WlGroupSelection.new(user: User.anonymous)

      assert_equal [], groups.allowed_to_display
    end
  end
end
