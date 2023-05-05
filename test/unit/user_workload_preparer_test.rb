# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class UserWorkloadPreparerTest < ActiveSupport::TestCase
    include Redmine::I18n

  test 'should respond to user_workload' do
    preparer = RedmineWorkload::UserWorkloadPreparer.new(data: {}, params: {})
    assert preparer.respond_to? :user_workload
  end

  test 'should repsond to time_span' do
    preparer = RedmineWorkload::UserWorkloadPreparer.new(data: {}, params: {})
    assert preparer.respond_to? :time_span
  end

  test 'should repsond to group_workload' do
    preparer = RedmineWorkload::UserWorkloadPreparer.new(data: {}, params: {})
    assert preparer.respond_to? :group_workload
  end

  test 'should return type of assignee' do
    preparer = RedmineWorkload::UserWorkloadPreparer.new(data: {}, params: {})
    assert_equal 'User', preparer.type(User.generate!)
  end

  test 'should return main group of assignee' do
    group = Group.generate!
    user = User.generate!
    user.groups << group
    user.create_wl_user_data(main_group: group.id)
    preparer = RedmineWorkload::UserWorkloadPreparer.new(data: {}, params: {})
    assert_equal group.name, preparer.main_group(user)
  end
end
