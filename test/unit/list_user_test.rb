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

  test "getOpenIssuesForUsersActiveInTimeSpan returns issue for given user if entirely in timespan" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 6, 1),
                            :due_date => Date::new(2013, 6, 5)
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue], ListUser::getOpenIssuesForUsersActiveInTimeSpan([user], firstDay..lastDay)
  end

  test "getOpenIssuesForUsersActiveInTimeSpan returns issue if only start date in time span" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 31),
                            :due_date => Date::new(2013, 6, 29),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue], ListUser::getOpenIssuesForUsersActiveInTimeSpan([user], firstDay..lastDay)
  end

  test "getOpenIssuesForUsersActiveInTimeSpan returns issue if only end date in time span" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 20),
                            :due_date => Date::new(2013, 5, 31),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue], ListUser::getOpenIssuesForUsersActiveInTimeSpan([user], firstDay..lastDay)
  end

  test "getOpenIssuesForUsersActiveInTimeSpan returns nothing if both start and end date before time span" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 20),
                            :due_date => Date::new(2013, 5, 30),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [], ListUser::getOpenIssuesForUsersActiveInTimeSpan([user], firstDay..lastDay)
  end

  test "getOpenIssuesForUsersActiveInTimeSpan returns issue if start date before and end date after time span" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 20),
                            :due_date => Date::new(2013, 6, 28),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [issue], ListUser::getOpenIssuesForUsersActiveInTimeSpan([user], firstDay..lastDay)
  end

  test "getOpenIssuesForUsersActiveInTimeSpan returns nothing if start date after end date" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 5, 20),
                            :due_date => Date::new(2013, 6, 28),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 6, 15)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [], ListUser::getOpenIssuesForUsersActiveInTimeSpan([user], firstDay..lastDay)
  end

  test "getOpenIssuesForUsersActiveInTimeSpan returns empty list if no users given" do
    user = User.generate!
    issue = Issue.generate!(:assigned_to => user,
                            :start_date => Date::new(2013, 6, 1),
                            :due_date => Date::new(2013, 6, 7),
                             :status => IssueStatus.find(1) # New, not closed
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 6, 5)

    assert_equal [], ListUser::getOpenIssuesForUsersActiveInTimeSpan([], firstDay..lastDay)
  end

  test "getOpenIssuesForUsersActiveInTimeSpan returns only issues of interesting users" do
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

    assert_equal [issue2], ListUser::getOpenIssuesForUsersActiveInTimeSpan([user2], firstDay..lastDay)
  end

  test "getOpenIssuesForUsersActiveInTimeSpan returns only open issues" do
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

    assert_equal [issue1], ListUser::getOpenIssuesForUsersActiveInTimeSpan([user], firstDay..lastDay)
  end

  test "getMonthsBetween returns [] if last day after first day" do
    firstDay = Date::new(2012, 3, 29)
    lastDay = Date::new(2012, 3, 28)

    assert_equal [], ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3] if both days in march 2012 and equal" do
    firstDay = Date::new(2012, 3, 27)
    lastDay = Date::new(2012, 3, 27)

    assert_equal [3], ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3] if both days in march 2012 and different" do
    firstDay = Date::new(2012, 3, 27)
    lastDay = Date::new(2012, 3, 28)

    assert_equal [3], ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3, 4, 5] if first day in march and last day in may" do
    firstDay = Date::new(2012, 3, 31)
    lastDay = Date::new(2012, 5, 1)

    assert_equal [3, 4, 5], ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  test "getMonthsBetween returns correct result timespan overlaps year boundary" do
    firstDay = Date::new(2011, 3, 3)
    lastDay = Date::new(2012, 5, 1)

    assert_equal (3..12).to_a.concat((1..5).to_a), ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
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

  # Set Saturday, Sunday and Wednesday to be a holiday, all others to be a
  # working day.
  def defineSaturdaySundayAndWendnesdayAsHoliday
    Setting.plugin_redmine_workload['general_workday_monday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_tuesday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_wednesday'] = '';
    Setting.plugin_redmine_workload['general_workday_thursday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_friday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_saturday'] = '';
    Setting.plugin_redmine_workload['general_workday_sunday'] = '';
  end

  def assertIssueTimesHashEquals(expected, actual)

    assert expected.is_a?(Hash), "Expected is no hash."
    assert actual.is_a?(Hash),   "Actual is no hash."

    assert_equal expected.keys.sort, actual.keys.sort, "Date keys are not equal"

    expected.keys.sort.each do |day|

      assert expected[day].is_a?(Hash), "Expected is no hashon day #{day.to_s}."
      assert actual[day].is_a?(Hash),   "Actual is no hash on day #{day.to_s}."

      assert expected[day].has_key?(:hours),      "On day #{day.to_s}, expected has no key :hours"
      assert expected[day].has_key?(:active),     "On day #{day.to_s}, expected has no key :active"
      assert expected[day].has_key?(:noEstimate), "On day #{day.to_s}, expected has no key :noEstimate"
      assert expected[day].has_key?(:holiday),    "On day #{day.to_s}, expected has no key :holiday"

      assert actual[day].has_key?(:hours),        "On day #{day.to_s}, actual has no key :hours"
      assert actual[day].has_key?(:active),       "On day #{day.to_s}, actual has no key :active"
      assert actual[day].has_key?(:noEstimate),   "On day #{day.to_s}, actual has no key :noEstimate"
      assert actual[day].has_key?(:holiday),      "On day #{day.to_s}, actual has no key :holiday"

      assert_in_delta expected[day][:hours],   actual[day][:hours], 1e-4, "On day #{day.to_s}, hours wrong"
      assert_equal expected[day][:active],     actual[day][:active],      "On day #{day.to_s}, active wrong"
      assert_equal expected[day][:noEstimate], actual[day][:noEstimate],  "On day #{day.to_s}, noEstimate wrong"
      assert_equal expected[day][:holiday],    actual[day][:holiday],     "On day #{day.to_s}, holiday wrong"
    end
  end

  test "getHoursForIssuesPerDay returns {} if time span empty" do

    issue = Issue.generate!(
                             :start_date => Date::new(2013, 5, 31),
                             :due_date => Date::new(2013, 6, 2),
                             :estimated_hours => 10.0,
                             :done_ratio => 10
                           )

    firstDay = Date::new(2013, 5, 31)
    lastDay = Date::new(2013, 5, 29)

    assertIssueTimesHashEquals Hash::new, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, firstDay)
  end

  test "getHoursForIssuesPerDay works if issue is completely in given time span and nothing done" do

    defineSaturdaySundayAndWendnesdayAsHoliday

    issue = Issue.generate!(
                             :start_date => Date::new(2013, 5, 31), # A Friday
                             :due_date => Date::new(2013, 6, 2),    # A Sunday
                             :estimated_hours => 10.0,
                             :done_ratio => 0
                           )

    firstDay = Date::new(2013, 5, 31) # A Friday
    lastDay = Date::new(2013, 6, 3)   # A Monday

    expectedResult = {
      Date::new(2013, 5, 31) => {
        :hours => 10.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      Date::new(2013, 6, 1) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      },
      Date::new(2013, 6, 2) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      },
      Date::new(2013, 6, 3) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => false
      }
    }

    assertIssueTimesHashEquals expectedResult, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, firstDay)
  end

  test "getHoursForIssuesPerDay works if issue lasts after time span and done_ratio > 0" do

    defineSaturdaySundayAndWendnesdayAsHoliday

    # 30 hours still need to be done, 3 working days until issue is finished.
    issue = Issue.generate!(
                             :start_date => Date::new(2013, 5, 28), # A Tuesday
                             :due_date => Date::new(2013, 6, 1),    # A Saturday
                             :estimated_hours => 40.0,
                             :done_ratio => 25
                           )

    firstDay = Date::new(2013, 5, 27) # A Monday, before issue starts
    lastDay = Date::new(2013, 5, 30)   # Thursday, before issue ends

    expectedResult = {
      # Monday, no holiday, before issue starts.
      Date::new(2013, 5, 27) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => false
      },
      # Tuesday, no holiday, issue starts here
      Date::new(2013, 5, 28) => {
        :hours => 10.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      # Wednesday, holiday
      Date::new(2013, 5, 29) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      },
      # Thursday, no holiday, last day of time span
      Date::new(2013, 5, 30) => {
        :hours => 10.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      }
    }

    assertIssueTimesHashEquals expectedResult, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, firstDay)
  end

  test "getHoursForIssuesPerDay works if issue starts before time span" do

    defineSaturdaySundayAndWendnesdayAsHoliday

    # 36 hours still need to be done, 2 working days until issue is due.
    # One day has already passed with 10% done.
    issue = Issue.generate!(
                             :start_date => Date::new(2013, 5, 28), # A Thursday
                             :due_date => Date::new(2013, 6, 1),    # A Saturday
                             :estimated_hours => 40.0,
                             :done_ratio => 10
                           )

    firstDay = Date::new(2013, 5, 29) # A Wednesday, before issue starts
    lastDay = Date::new(2013, 6, 1)   # Saturday, before issue ends

    expectedResult = {
      # Wednesday, holiday, first day of time span.
      Date::new(2013, 5, 29) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      },
      # Thursday, no holiday
      Date::new(2013, 5, 30) => {
        :hours => 18.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      # Friday, no holiday
      Date::new(2013, 5, 31) => {
        :hours => 18.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      # Saturday, holiday, last day of time span
      Date::new(2013, 6, 1) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      }
    }

    assertIssueTimesHashEquals expectedResult, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, firstDay)
  end

  test "getHoursForIssuesPerDay works if issue completely before time span" do

    defineSaturdaySundayAndWendnesdayAsHoliday

    # 10 hours still need to be done, but issue is overdue. Remaining hours need
    # to be put on first working day of time span.
    issue = Issue.generate!(
                             :start_date => nil,                 # No start date
                             :due_date => Date::new(2013, 6, 1), # A Saturday
                             :estimated_hours => 100.0,
                             :done_ratio => 90
                           )

    firstDay = Date::new(2013, 6, 2)  # Sunday, after issue due date
    lastDay = Date::new(2013, 6, 4)   # Tuesday

    expectedResult = {
      # Sunday, holiday.
      Date::new(2013, 6, 2) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => true
      },
      # Monday, no holiday, first working day in time span.
      Date::new(2013, 6, 3) => {
        :hours => 10.0,
        :active => false,
        :noEstimate => false,
        :holiday => false
      },
      # Tuesday, no holiday
      Date::new(2013, 6, 4) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => false
      }
    }

    assertIssueTimesHashEquals expectedResult, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, firstDay)
  end

  test "getHoursForIssuesPerDay works if issue has no due date" do

    defineSaturdaySundayAndWendnesdayAsHoliday

    # 10 hours still need to be done.
    issue = Issue.generate!(
                             :start_date => Date::new(2013, 6, 3), # A Tuesday
                             :due_date => nil,
                             :estimated_hours => 100.0,
                             :done_ratio => 90
                           )

    firstDay = Date::new(2013, 6, 2)  # Sunday
    lastDay = Date::new(2013, 6, 4)   # Tuesday

    expectedResult = {
      # Sunday, holiday.
      Date::new(2013, 6, 2) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => true
      },
      # Monday, no holiday, first working day in time span.
      Date::new(2013, 6, 3) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => true,
        :holiday => false
      },
      # Tuesday, no holiday
      Date::new(2013, 6, 4) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => true,
        :holiday => false
      }
    }

    assertIssueTimesHashEquals expectedResult, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, firstDay)
  end

  test "getHoursForIssuesPerDay works if issue has no start date" do

    defineSaturdaySundayAndWendnesdayAsHoliday

    # 10 hours still need to be done.
    issue = Issue.generate!(
                             :start_date => nil,
                             :due_date => Date::new(2013, 6, 3),
                             :estimated_hours => 100.0,
                             :done_ratio => 90
                           )

    firstDay = Date::new(2013, 6, 2)  # Sunday
    lastDay = Date::new(2013, 6, 4)   # Tuesday

    expectedResult = {
      # Sunday, holiday.
      Date::new(2013, 6, 2) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      },
      # Monday, no holiday, first working day in time span.
      Date::new(2013, 6, 3) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => true,
        :holiday => false
      },
      # Tuesday, no holiday
      Date::new(2013, 6, 4) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => false
      }
    }

    assertIssueTimesHashEquals expectedResult, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, firstDay)
  end

  test "getHoursForIssuesPerDay works if in time span and issue overdue" do

    defineSaturdaySundayAndWendnesdayAsHoliday

    # 10 hours still need to be done, but issue is overdue. Remaining hours need
    # to be put on first working day of time span.
    issue = Issue.generate!(
                             :start_date => nil,                 # No start date
                             :due_date => Date::new(2013, 6, 1), # A Saturday
                             :estimated_hours => 100.0,
                             :done_ratio => 90
                           )

    firstDay = Date::new(2013, 5, 30)  # Thursday
    lastDay = Date::new(2013, 6, 4)    # Tuesday
    today = Date::new(2013, 6, 2)      # After issue end

    expectedResult = {
      # Thursday, in the past.
      Date::new(2013, 5, 30) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      # Friday, in the past.
      Date::new(2013, 5, 31) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      # Saturday, holiday, in the past.
      Date::new(2013, 6, 1) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      },
      # Sunday, holiday.
      Date::new(2013, 6, 2) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => true
      },
      # Monday, no holiday, first working day in time span.
      Date::new(2013, 6, 3) => {
        :hours => 10.0,
        :active => false,
        :noEstimate => false,
        :holiday => false
      },
      # Tuesday, no holiday
      Date::new(2013, 6, 4) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => false
      }
    }

    assertIssueTimesHashEquals expectedResult, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, today)
  end

  test "getHoursForIssuesPerDay works if issue is completely in given time span, but has started" do

    defineSaturdaySundayAndWendnesdayAsHoliday

    issue = Issue.generate!(
                             :start_date => Date::new(2013, 5, 31), # A Friday
                             :due_date => Date::new(2013, 6, 4),    # A Tuesday
                             :estimated_hours => 10.0,
                             :done_ratio => 0
                           )

    firstDay = Date::new(2013, 5, 31) # A Friday
    lastDay = Date::new(2013, 6, 5)   # A Wednesday
    today = Date::new(2013, 6, 2)     # A Sunday

    expectedResult = {
      # Friday
      Date::new(2013, 5, 31) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      # Saturday
      Date::new(2013, 6, 1) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      },
      # Sunday
      Date::new(2013, 6, 2) => {
        :hours => 0.0,
        :active => true,
        :noEstimate => false,
        :holiday => true
      },
      # Monday
      Date::new(2013, 6, 3) => {
        :hours => 5.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      # Tuesday
      Date::new(2013, 6, 4) => {
        :hours => 5.0,
        :active => true,
        :noEstimate => false,
        :holiday => false
      },
      # Wednesday
      Date::new(2013, 6, 5) => {
        :hours => 0.0,
        :active => false,
        :noEstimate => false,
        :holiday => true
      }
    }

    assertIssueTimesHashEquals expectedResult, ListUser::getHoursForIssuesPerDay(issue, firstDay..lastDay, today)
  end

  test "foobar" do
    user = User.generate!

    issue1 = Issue.generate!(
                             :assigned_to => user,
                             :start_date => Date::new(2013, 5, 31), # A Friday
                             :due_date => Date::new(2013, 6, 4),    # A Tuesday
                             :estimated_hours => 10.0,
                             :done_ratio => 50,
                             :status => IssueStatus.find(1) # New, not closed
                            )

    issue2 = Issue.generate!(
                             :assigned_to => user,
                             :start_date => Date::new(2013, 6, 3), # A Friday
                             :due_date => Date::new(2013, 6, 6),    # A Tuesday
                             :estimated_hours => 30.0,
                             :done_ratio => 50,
                             :status => IssueStatus.find(1) # New, not closed
                            )

    firstDay = Date::new(2013, 5, 25)
    lastDay = Date::new(2013, 6, 4)
    today = Date::new(2013, 5, 31)

    puts "foobar: " + ListUser::getHoursPerUserIssueAndDay([user], firstDay..lastDay, today).inspect
  end
end
