require File.expand_path('../../test_helper', __FILE__)

class ListUserTest < ActiveSupport::TestCase

  # Load everything, I'm sick of the errors.
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns issue for given user if entirely in timespan" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 6, 1),
                            :due_date => Date::new(2013, 6, 5)
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([user], firstDay, lastDay)
  end

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns issue if only start date in time span" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 31),
                            :due_date => Date::new(2013, 6, 29),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([user], firstDay, lastDay)
  end

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns issue if only end date in time span" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 20),
                            :due_date => Date::new(2013, 5, 31),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([user], firstDay, lastDay)
  end

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns nothing if both start and end date before time span" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 20),
                            :due_date => Date::new(2013, 5, 30),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([user], firstDay, lastDay)
  end

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns issue if start date before and end date after time span" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 20),
                            :due_date => Date::new(2013, 6, 28),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([user], firstDay, lastDay)
  end

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns nothing if start date after end date" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 20),
                            :due_date => Date::new(2013, 6, 28),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 6, 15)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([user], firstDay, lastDay)
  end

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns empty list if no users given" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 6, 1),
                            :due_date => Date::new(2013, 6, 7),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([], firstDay, lastDay)
  end

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns only issues of interesting users" do
    user1 = User.generate!
    user2 = User.generate!

    issue1 = Issue.generate!(:assigned_to => user1,
                             :start_date => Date::new(2013, 6, 1),
                             :due_date => Date::new(2013, 6, 7),
                             :status => IssueStatus.find(1) # New, not closed
                            )

    issue2 = Issue.generate!(:assigned_to => user2,
                             :start_date => Date::new(2013, 5, 31),
                             :due_date => Date::new(2013, 6, 2),
                             :status => IssueStatus.find(1) # New, not closed
                            )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue2], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([user2], firstDay, lastDay)
  end

  test "getOpenIssuesForUsersActiveInGivenTimeSpan returns only open issues" do
    user = User.generate!

    issue1 = Issue.generate!(:assigned_to => user,
                             :start_date => Date::new(2013, 6, 1),
                             :due_date => Date::new(2013, 6, 7),
                             :status => IssueStatus.find(1) # New, not closed
                            )

    issue2 = Issue.generate!(:assigned_to => user,
                             :start_date => Date::new(2013, 5, 31),
                             :due_date => Date::new(2013, 6, 2),
                             :status => IssueStatus.find(6) # Rejected, closed
                            )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue1], ListUser::getOpenIssuesForUsersActiveInGivenTimeSpan([user], firstDay, lastDay)
  end
end
