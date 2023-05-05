# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class WlIssueQueryTest < ActiveSupport::TestCase
  include RedmineWorkload::WorkloadObjectHelper
  include RedmineWorkload::WlIssueQuery

    fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
            :users, :issue_statuses, :enumerations, :roles

    def setup
      @manager = roles :roles_001
      @user1 = User.generate!
      @user2 = User.generate!
      @project1 = Project.generate!
      User.add_to_project(@user1, @project1, @manager)
      User.add_to_project(@user2, @project1, @manager)
      @status_new = IssueStatus.find(1)
      @parent_issue = Issue.generate!(assigned_to: @user1,
                                      status: @status_new,
                                      project: @project1)
      @child_issue = Issue.generate!(assigned_to: @user1,
                                    status: @status_new,
                                    project: @project1,
                                    parent_issue_id: @parent_issue.id)
    end

    def teardown
      @child_issue.destroy
      @parent_issue.destroy
      @user1.destroy
      @user2.destroy
      @project1.destroy
      Setting.clear_cache
    end

    test 'should query parent and child issues if any' do
      with_plugin_settings 'workload_of_parent_issues' => 'checked' do
        expected_ids = [@parent_issue.id, @child_issue.id]
        query_result = open_issues_for_users([@user1, @user2])
        query_result_ids = query_result.pluck(:id).sort
        assert_equal expected_ids, query_result_ids
      end
    end
  end
end
