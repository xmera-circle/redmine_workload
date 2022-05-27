# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class GroupUserDummyTest < ActiveSupport::TestCase
  include WlUserDataFinder
  include WorkloadsHelper

  fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
           :users, :issue_statuses, :enumerations, :roles

  def setup
    @group = Group.generate!
    @user1 = User.generate!
    @user1.groups << @group
    @user1_wl_data = find_user_workload_data(@user1.id)
    @user1_wl_data.main_group = @group.id
    @user1_wl_data.save
    @user2 = User.generate!
    @user2.groups << @group
    @user2_wl_data = find_user_workload_data(@user2.id)
    @user2_wl_data.main_group = @group.id
    @user2_wl_data.save
    @dummy = GroupUserDummy.new(group: @group)
  end

  test 'should respond to group' do
    assert @dummy.respond_to? :group
  end

  test 'should respond to lastname' do
    assert @dummy.respond_to? :lastname
  end

  test 'should respond to name' do
    assert @dummy.respond_to? :name
  end

  test 'should respond to main_group' do
    assert @dummy.respond_to? :main_group
  end

  test 'should respond to type' do
    assert @dummy.respond_to? :type
  end

  test 'should respond to threshold_lowload_min' do
    assert @dummy.respond_to? :threshold_lowload_min
  end

  test 'should respond to threshold_normalload_min' do
    assert @dummy.respond_to? :threshold_normalload_min
  end

  test 'should respond to threshold_highload_min' do
    assert @dummy.respond_to? :threshold_highload_min
  end

  test 'should sum up threshold of group members when unset' do
    group = Group.generate!
    user1 = User.generate!
    user1.groups << group
    user1_wl_data = WlUserData.new(user_id: user1.id)
    user1_wl_data.main_group = group.id
    user1_wl_data.save
    user2 = User.generate!
    user2.groups << group
    user2_wl_data = WlUserData.new(user_id: user2.id)
    user2_wl_data.main_group = group.id
    user2_wl_data.save
    dummy = GroupUserDummy.new(group: group)
    expected = 0.0
    thresholds = %i[threshold_lowload_min threshold_normalload_min threshold_highload_min]
    thresholds.each do |threshold|
      current = dummy.send :sum_up, threshold
      assert_equal expected, current
    end
  end

  test 'should sum up thresholds of group members when given' do
    lowload1, normalload1, highload1 = [2, 4, 6]
    @user1_wl_data.threshold_lowload_min = lowload1
    @user1_wl_data.threshold_normalload_min = normalload1
    @user1_wl_data.threshold_highload_min = highload1
    @user1_wl_data.save
    lowload2, normalload2, highload2 = [3, 5, 7]
    @user2_wl_data.threshold_lowload_min = lowload2
    @user2_wl_data.threshold_normalload_min = normalload2
    @user2_wl_data.threshold_highload_min = highload2
    @user2_wl_data.save

    expected_threshold_lowload_min = lowload1 + lowload2
    current_threshold_lowload_min = @dummy.send :sum_up, :threshold_lowload_min
    assert_equal expected_threshold_lowload_min, current_threshold_lowload_min

    expected_threshold_normalload_min = normalload1 + normalload2
    current_threshold_normalload_min = @dummy.send :sum_up, :threshold_normalload_min
    assert_equal expected_threshold_normalload_min, current_threshold_normalload_min

    expected_threshold_highload_min = highload1 + highload2
    current_threshold_highload_min = @dummy.send :sum_up, :threshold_highload_min
    assert_equal expected_threshold_highload_min, current_threshold_highload_min
  end
end
