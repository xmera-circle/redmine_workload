# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class GroupWorkloadTest < ActiveSupport::TestCase
  include RedmineWorkload::WorkloadObjectHelper
  fixtures :roles, :projects, :issue_statuses, :trackers, :enumerations, :users

  def setup
    @user = users :users_001
    @manager = roles :roles_001
    @manager.add_permission! :view_all_workloads
    @group_workload = prepare_group_workload(user: @user, role: @manager, groups: groups_defined)
    @empty_group_workload = prepare_group_workload(user: @user, role: @manager)
  end

  test 'should respond to by_group' do
    assert @group_workload.respond_to?(:by_group)
  end

  test 'should respond to time_span' do
    assert @group_workload.respond_to?(:time_span)
  end

  test 'should respond to user_workload' do
    assert @group_workload.respond_to?(:user_workload)
  end

  test 'define_group_members should return empty hash when no groups selected' do
    expected = {}
    current = @empty_group_workload.send :group_members
    assert_equal expected, current
  end

  test 'should select group members only once' do
    selected_groups = @group_workload.send(:selected_groups)
    group1 = selected_groups.first
    group2 = selected_groups.last
    group_members = @group_workload.send(:group_members)
    member_list1 = group_members[group1].keys.map(&:id)
    member_list2 = group_members[group2].keys.map(&:id)
    count = (member_list1 | member_list2).count
    assert_equal 3, count
    current = member_list1 & member_list2
    expected = []
    assert_equal expected, current
  end

  test 'should list group_user_dummy first' do
    sorted_user_workload = @group_workload.send(:sorted_user_workload)
    assert sorted_user_workload.keys.first.is_a? GroupUserDummy
  end
end
