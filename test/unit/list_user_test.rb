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

  test "getMonthsBetween returns [] if last day after first day" do
    firstDay = Date::new(2012, 3, 29)
    lastDay = Date::new(2012, 3, 28)

    assert_equal [], ListUser::getMonthsBetween(firstDay, lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3] if both days in march 2012 and equal" do
    firstDay = Date::new(2012, 3, 27)
    lastDay = Date::new(2012, 3, 27)

    assert_equal [3], ListUser::getMonthsBetween(firstDay, lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3] if both days in march 2012 and different" do
    firstDay = Date::new(2012, 3, 27)
    lastDay = Date::new(2012, 3, 28)

    assert_equal [3], ListUser::getMonthsBetween(firstDay, lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3, 4, 5] if first day in march and last day in may" do
    firstDay = Date::new(2012, 3, 31)
    lastDay = Date::new(2012, 5, 1)

    assert_equal [3, 4, 5], ListUser::getMonthsBetween(firstDay, lastDay).map(&:month)
  end

  test "getMonthsBetween returns correct result timespan overlaps year boundary" do
    firstDay = Date::new(2011, 3, 3)
    lastDay = Date::new(2012, 5, 1)

    assert_equal (3..12).to_a.concat((1..5).to_a), ListUser::getMonthsBetween(firstDay, lastDay).map(&:month)
  end

  test "getDaysInMonth returns 31 for december 2012" do
    assert_equal 31, ListUser::getDaysInMonth(Date::new(2012, 12, 6))
  end

  test "getDaysInMonth returns 29 for february 2012" do
    assert_equal 29, ListUser::getDaysInMonth(Date::new(2012, 2, 23))
  end

  test "getDaysInMonth returns 28 for february 2013" do
    assert_equal 28, ListUser::getDaysInMonth(Date::new(2013, 2, 1))
  end
end
