# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class GroupWorkloadPreparerTest < ActiveSupport::TestCase
    include Redmine::I18n

  test 'should respond to user_workload' do
    preparer = RedmineWorkload::GroupWorkloadPreparer.new(data: {}, params: {})
    assert preparer.respond_to? :user_workload
  end

  test 'should repsond to time_span' do
    preparer = RedmineWorkload::GroupWorkloadPreparer.new(data: {}, params: {})
    assert preparer.respond_to? :time_span
  end

  test 'should repsond to group_workload' do
    preparer = RedmineWorkload::GroupWorkloadPreparer.new(data: {}, params: {})
    assert preparer.respond_to? :group_workload
  end

  test 'should return type of assignee' do
    preparer = RedmineWorkload::GroupWorkloadPreparer.new(data: {}, params: {})
    assert_equal l(:label_aggregation), preparer.type(Group.generate!)
    assert_equal 'User', preparer.type(User.generate!)
  end

  test 'should return main group of assignee' do
    group = Group.generate!
    dummy = GroupUserDummy.new(group: group)
    user = User.generate!
    user.groups << group
    user.create_wl_user_data(main_group: group.id)
    preparer = RedmineWorkload::GroupWorkloadPreparer.new(data: {}, params: {})
    assert_equal group.name, preparer.main_group(user)
    assert_equal dummy.main_group.name, preparer.main_group(dummy)
  end
end
