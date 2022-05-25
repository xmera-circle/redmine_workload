# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class GroupWorkloadTest < ActiveSupport::TestCase
  include RedmineWorkload::WorkloadObjectHelper
  fixtures :roles, :projects, :issue_statuses, :trackers, :enumerations, :users

  def setup
    @user = users :users_001
    @manager = roles :roles_001
    @manager.add_permission! :view_all_workloads
  end

  test 'should respond to by_group' do
    group_workload = prepare_group_workload(user: @user,
                                            role: @manager,
                                            groups: groups_defined,
                                            main_group_strategy: :distinct,
                                            vacation_strategy: :distinct)
    assert group_workload.respond_to?(:by_group)
  end

  test 'should respond to time_span' do
    group_workload = prepare_group_workload(user: @user,
                                            role: @manager,
                                            groups: groups_defined,
                                            main_group_strategy: :distinct,
                                            vacation_strategy: :distinct)
    assert group_workload.respond_to?(:time_span)
  end

  test 'should respond to user_workload' do
    group_workload = prepare_group_workload(user: @user,
                                            role: @manager,
                                            groups: groups_defined,
                                            main_group_strategy: :distinct,
                                            vacation_strategy: :distinct)
    assert group_workload.respond_to?(:user_workload)
  end

  test 'define_group_members should return empty hash when no groups selected' do
    empty_group_workload = prepare_group_workload(user: @user,
                                                  role: @manager,
                                                  main_group_strategy: :distinct,
                                                  vacation_strategy: :distinct)
    expected = {}
    current = empty_group_workload.send :group_members
    assert_equal expected, current
  end

  test 'should select group members only once' do
    group_workload = prepare_group_workload(user: @user,
                                            role: @manager,
                                            groups: groups_defined,
                                            main_group_strategy: :distinct,
                                            vacation_strategy: :distinct)
    selected_groups = group_workload.send(:selected_groups)
    group1 = selected_groups.first
    group2 = selected_groups.last
    group_members = group_workload.send(:group_members)
    member_list1 = group_members[group1].keys.map(&:id)
    member_list2 = group_members[group2].keys.map(&:id)
    count = (member_list1 | member_list2).count
    assert_equal 3, count
    current = member_list1 & member_list2
    expected = []
    assert_equal expected, current
  end

  test 'should list group_user_dummy first' do
    group_workload = prepare_group_workload(user: @user,
                                            role: @manager,
                                            groups: groups_defined,
                                            main_group_strategy: :distinct,
                                            vacation_strategy: :distinct)
    sorted_user_workload = group_workload.send(:sorted_user_workload)
    assert sorted_user_workload.keys.first.is_a? GroupUserDummy
  end

  test 'should return no holiday when only one group member is on vacation for a given day' do
    group_workload = prepare_group_workload(user: @user,
                                            role: @manager,
                                            groups: groups_defined,
                                            main_group_strategy: :same,
                                            vacation_strategy: :distinct)

    user1_id = group_workload.send(:users).send(:users).first
    user1 = User.find(user1_id)
    assert user1.is_a? User
    group = Group.find(user1.main_group_id)

    ## The following checks are only required for the error analysis if any
    # assert user1.wl_user_vacations.where(date_from: first_day, date_to: first_day).take.presence
    # assert WlUserVacation.where(user_id: user1.id, date_from: first_day, date_to: first_day).take.presence

    # user2_id = group_workload.send(:users).send(:users).last
    # user2 = User.find(user2_id)
    # assert user2.is_a? User

    # assert_not_equal user1, user2

    # assert_equal group.id, user2.main_group_id
    # assert user2.wl_user_vacations.where(date_from: last_day, date_to: last_day).take.presence
    # assert WlUserVacation.where(user_id: user2.id, date_from: last_day, date_to: last_day).take.presence

    # assert_equal 3, group_workload.user_workload.keys.count # GroupUserDummy + user1 + user2
    # assert_equal 3, group_workload.send(:group_members)[group].keys.count
    ## end

    expected = false
    current = group_workload.send(:holiday_at, first_day, :total, group)
    assert_equal expected, current
  end

  test 'should return holiday when all group members are on vacation for a given day' do
    group_workload = prepare_group_workload(user: @user,
                                            role: @manager,
                                            groups: groups_defined,
                                            main_group_strategy: :same,
                                            vacation_strategy: :same)
    user1_id = group_workload.send(:users).send(:users).first
    user1 = User.find(user1_id)
    assert user1.is_a? User
    group = Group.find(user1.main_group_id)

    ## The following checks are only required for the error analysis if any
    # assert user1.wl_user_vacations.where(date_from: first_day, date_to: first_day).take.presence
    # assert WlUserVacation.where(user_id: user1.id, date_from: first_day, date_to: first_day).take.presence

    # user2_id = group_workload.send(:users).send(:users).last
    # user2 = User.find(user2_id)
    # assert user2.is_a? User

    # assert_equal group.id, user2.main_group_id
    # assert user2.wl_user_vacations.where(date_from: first_day, date_to: first_day).take.presence
    # assert WlUserVacation.where(user_id: user2.id, date_from: first_day, date_to: first_day).take.presence

    # assert_equal 3, group_workload.user_workload.keys.count # GroupUserDummy + user1 + user2
    # assert_equal 3, group_workload.send(:group_members)[group].keys.count
    ## end

    expected = true
    current = group_workload.send(:holiday_at, first_day, :total, group)
    assert_equal expected, current
  end

  test 'should count unscheduled issues and hours on group level' do
    group1, group2 = groups_defined
    workload = prepare_group_workload(user: @user,
                                      role: @manager,
                                      groups: [group1, group2],
                                      main_group_strategy: :distinct,
                                      vacation_strategy: :distinct)

    assert_equal 2, workload.by_group[group1][:unscheduled_number]
    assert_equal 24.0, workload.by_group[group1][:unscheduled_hours]
    assert_equal 0, workload.by_group[group2][:unscheduled_number]
    assert_equal 0.0, workload.by_group[group2][:unscheduled_hours]
  end

  test 'should calculate day dependent threshold values for group workload' do
    group1, group2 = groups_defined
    workload = prepare_group_workload(user: @user,
                                      role: @manager,
                                      groups: [group1, group2],
                                      main_group_strategy: :same, # group1
                                      # first_day for one user and last_day for the other
                                      vacation_strategy: :distinct)

    # threshold default values: highload = 6, lowload = 3, normalload = 4
    # holiday for one of two group members
    assert_equal 3.0, workload.send(:threshold_at, first_day, :lowload, group1)
    assert_equal 4.0, workload.send(:threshold_at, first_day, :normalload, group1)
    assert_equal 6.0, workload.send(:threshold_at, first_day, :highload, group1)
    # Saturday
    assert_equal 0.0, workload.send(:threshold_at, first_day + 3, :lowload, group1)
    assert_equal 0.0, workload.send(:threshold_at, first_day + 3, :normalload, group1)
    assert_equal 0.0, workload.send(:threshold_at, first_day + 3, :highload, group1)
    # both group members are working
    assert_equal 6.0, workload.send(:threshold_at, first_day + 1, :lowload, group1)
    assert_equal 8.0, workload.send(:threshold_at, first_day + 1, :normalload, group1)
    assert_equal 12.0, workload.send(:threshold_at, first_day + 1, :highload, group1)
  end
end
