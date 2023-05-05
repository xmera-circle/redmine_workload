# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WorkloadsControllerTest < ActionDispatch::IntegrationTest
    include RedmineWorkload::AuthenticateUser

    fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
            :users, :issue_statuses, :enumerations, :roles

    test 'should not get index when not allowed to' do
      log_user('jsmith', 'jsmith')

      get workloads_path
      assert_response :forbidden
    end

    test 'should get index' do
      manager = roles :roles_001
      manager.add_permission! :view_all_workloads
      log_user('jsmith', 'jsmith')

      get workloads_path
      assert_response :success
    end

    test 'should get index with format csv' do
      manager = roles :roles_001
      manager.add_permission! :view_all_workloads
      log_user('jsmith', 'jsmith')

      get workloads_path(format: 'csv')
      assert_response :success
    end
  end
end
