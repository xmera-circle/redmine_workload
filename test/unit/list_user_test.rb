# -*- encoding : utf-8 -*-
require File.expand_path('../../test_helper', __FILE__)

class ListUserTest < ActiveSupport::TestCase

  fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
           :users, :issue_statuses, :enumerations, :roles


  test "getOpenIssuesForUsers returns empty list if no users given" do
    assert_equal [], ListUser::getOpenIssuesForUsers([])
  end

  test "getOpenIssuesForUsers returns only issues of interesting users" do
    user1 = User.generate!
    user2 = User.generate!
    
    project1 = Project.generate!
    
    User.add_to_project(user1, project1, Role.find_by_name('Manager')) 
    User.add_to_project(user2, project1, Role.find_by_name('Manager'))

    issue1 = Issue.generate!(:assigned_to => user1,
                             :status => IssueStatus.find(1), # New, not closed
                             :project => project1
                            )

    issue2 = Issue.generate!(:assigned_to => user2,
                             :status => IssueStatus.find(1), # New, not closed
                             :project => project1
                            )

    assert_equal [issue2], ListUser::getOpenIssuesForUsers([user2])
  end

  test "getOpenIssuesForUsers returns only open issues" do
    user = User.generate!
    project1 = Project.generate!
    
    User.add_to_project(user, project1, Role.find_by_name('Manager')) 

    issue1 = Issue.generate!(:assigned_to => user,
                             #:status => IssueStatus.find(6), # rejected, closed
                             #:status_id => 2,
                             :project => project1
                             )
    issue1.status_id = 2
    issue1.status.update! :is_closed => true
    issue1.save!

    issue2 = Issue.generate!(:assigned_to => user,
                             # :status => IssueStatus.find(1), # New, not closed
                             :status_id => 1,
                             :project => project1
                              )
            
    assert_equal [issue2], ListUser::getOpenIssuesForUsers([user])
  end

  test "getMonthsBetween returns [] if last day after first day" do
    firstDay = Date::new(2012, 3, 29)
    lastDay = Date::new(2012, 3, 28)
    
    # TODO: Since ListUser::getMonthsInTimespan got changed this assert need repair
    # assert_equal [], ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3] if both days in march 2012 and equal" do
    firstDay = Date::new(2012, 3, 27)
    lastDay = Date::new(2012, 3, 27)
    
    # TODO: Since ListUser::getMonthsInTimespan got changed this assert need repair
    # assert_equal [3], ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3] if both days in march 2012 and different" do
    firstDay = Date::new(2012, 3, 27)
    lastDay = Date::new(2012, 3, 28)
    
    # TODO: Since ListUser::getMonthsInTimespan got changed this assert need repair
    # assert_equal [3], ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  test "getMonthsBetween returns [3, 4, 5] if first day in march and last day in may" do
    firstDay = Date::new(2012, 3, 31)
    lastDay = Date::new(2012, 5, 1)
    
    # TODO: Since ListUser::getMonthsInTimespan got changed this assert need repair
    #assert_equal [3, 4, 5], ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  test "getMonthsBetween returns correct result timespan overlaps year boundary" do
    firstDay = Date::new(2011, 3, 3)
    lastDay = Date::new(2012, 5, 1)
    
    # TODO: Since ListUser::getMonthsInTimespan got changed this assert need repair
    #assert_equal (3..12).to_a.concat((1..5).to_a), ListUser::getMonthsInTimespan(firstDay..lastDay).map(&:month)
  end

  # Set Saturday, Sunday and Wednesday to be a holiday, all others to be a
  # working day.
  def defineSaturdaySundayAndWendnesdayAsHoliday
    Setting['plugin_redmine_workload']['general_workday_monday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_tuesday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_wednesday'] = '';
    Setting['plugin_redmine_workload']['general_workday_thursday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_friday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_saturday'] = '';
    Setting['plugin_redmine_workload']['general_workday_sunday'] = '';
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

  test "getHoursPerUserIssueAndDay returns correct structure" do
    user = User.generate!
    
    project1 = Project.generate!
    project2 = Project.generate!
    
    User.add_to_project(user, project1, Role.find_by_name('Manager'))
    User.add_to_project(user, project2, Role.find_by_name('Manager'))

    issue1 = Issue.generate!(
                             :assigned_to => user,
                             :start_date => Date::new(2013, 5, 31), # A Friday
                             :due_date => Date::new(2013, 6, 4),    # A Tuesday
                             :estimated_hours => 10.0,
                             :done_ratio => 50,
                             :status => IssueStatus.find(1), # New, not closed
                             :project => project1
                            )

    issue2 = Issue.generate!(
                             :assigned_to => user,
                             :start_date => Date::new(2013, 6, 3), # A Friday
                             :due_date => Date::new(2013, 6, 6),    # A Tuesday
                             :estimated_hours => 30.0,
                             :done_ratio => 50,
                             :status => IssueStatus.find(1), # New, not closed
                             :project => project2
                            )

    firstDay = Date::new(2013, 5, 25)
    lastDay = Date::new(2013, 6, 4)
    today = Date::new(2013, 5, 31)

    workloadData = ListUser::getHoursPerUserIssueAndDay(Issue.assigned_to(user).to_a, firstDay..lastDay, today)

    assert workloadData.has_key?(user)

    # Check structure returns the 4 elements :overdue_hours, :overdue_number, :total, :invisible
    # AND 2 Projects
    assert_equal 6, workloadData[user].keys.count
    assert workloadData[user].has_key?(:overdue_hours)
    assert workloadData[user].has_key?(:overdue_number)
    assert workloadData[user].has_key?(:total)
    assert workloadData[user].has_key?(:invisible)    
    assert workloadData[user].has_key?(project1)
    assert workloadData[user].has_key?(project2)
  end

  test "getEstimatedTimeForIssue works for issue without children." do
    issue = Issue.generate!(:estimated_hours => 13.2)
    assert_in_delta 13.2, ListUser::getEstimatedTimeForIssue(issue), 1e-4
  end

  test "getEstimatedTimeForIssue works for issue with children." do
    parent = Issue.generate!(:estimated_hours => 3.6)
    child1 = Issue.generate!(:estimated_hours => 5.0, :parent_issue_id => parent.id, :done_ratio => 90)
    child2 = Issue.generate!(:estimated_hours => 9.0, :parent_issue_id => parent.id)

    # Force parent to reload so the data from the children is incorporated.
    parent.reload

    assert_in_delta 0.0, ListUser::getEstimatedTimeForIssue(parent), 1e-4
    assert_in_delta 0.5, ListUser::getEstimatedTimeForIssue(child1), 1e-4
    assert_in_delta 9.0, ListUser::getEstimatedTimeForIssue(child2), 1e-4
  end

  test "getEstimatedTimeForIssue works for issue with grandchildren." do
    parent = Issue.generate!(:estimated_hours => 4.5)
    child = Issue.generate!(:estimated_hours => 5.0, :parent_issue_id => parent.id)
    grandchild = Issue.generate!(:estimated_hours => 9.0, :parent_issue_id => child.id, :done_ratio => 40)

    # Force parent and child to reload so the data from the children is
    # incorporated.
    parent.reload
    child.reload

    assert_in_delta 0.0, ListUser::getEstimatedTimeForIssue(parent), 1e-4
    assert_in_delta 0.0, ListUser::getEstimatedTimeForIssue(child), 1e-4
    assert_in_delta 5.4, ListUser::getEstimatedTimeForIssue(grandchild), 1e-4
  end

  test "getLoadClassForHours returns \"none\" for workloads below threshold for low workload" do
    Setting['plugin_redmine_workload']['threshold_lowload_min'] = 0.1
    Setting['plugin_redmine_workload']['threshold_normalload_min'] = 5.0
    Setting['plugin_redmine_workload']['threshold_highload_min'] = 7.0

    assert_equal "none", ListUser::getLoadClassForHours(0.05)
  end

  test "getLoadClassForHours returns \"low\" for workloads between thresholds for low and normal workload" do
    Setting['plugin_redmine_workload']['threshold_lowload_min'] = 0.1
    Setting['plugin_redmine_workload']['threshold_normalload_min'] = 5.0
    Setting['plugin_redmine_workload']['threshold_highload_min'] = 7.0

    assert_equal "low", ListUser::getLoadClassForHours(3.5)
  end

  test "getLoadClassForHours returns \"normal\" for workloads between thresholds for normal and high workload" do
    Setting['plugin_redmine_workload']['threshold_lowload_min'] = 0.1
    Setting['plugin_redmine_workload']['threshold_normalload_min'] = 2.0
    Setting['plugin_redmine_workload']['threshold_highload_min'] = 7.0

    assert_equal "normal", ListUser::getLoadClassForHours(3.5)
  end

  test "getLoadClassForHours returns \"high\" for workloads above threshold for high workload" do
    Setting['plugin_redmine_workload']['threshold_lowload_min'] = 0.1
    Setting['plugin_redmine_workload']['threshold_normalload_min'] = 2.0
    Setting['plugin_redmine_workload']['threshold_highload_min'] = 7.0

    assert_equal "high", ListUser::getLoadClassForHours(10.5)
  end

  test "getUsersAllowedToDisplay returns an empty array if the current user is anonymus." do
    User.current = User.anonymous

    assert_equal [], ListUser::getUsersAllowedToDisplay
  end

  test "getUsersAllowedToDisplay returns only the user himself if user has no role assigned." do
    User.current = User.generate!

    assert_equal [User.current].map(&:id).sort, ListUser::getUsersAllowedToDisplay.map(&:id).sort
  end

  test "getUsersAllowedToDisplay returns all users if the current user is a admin." do
    User.current = User.generate!
    # Make this user an admin (can't do it in the attributes?!?)
    User.current.admin = true

    assert_equal User.active.map(&:id).sort, ListUser::getUsersAllowedToDisplay.map(&:id).sort
  end

  test "getUsersAllowedToDisplay returns exactly project members if user has right to see workload of project members." do
    User.current = User.generate!
    project = Project.generate!

    projectManagerRole = Role.generate!(:name => 'Project manager',
                                        :permissions => [:view_project_workload])

    User.add_to_project(User.current, project, [projectManagerRole]);

    projectMember1 = User.generate!
    User.add_to_project(projectMember1, project)
    projectMember2 = User.generate!
    User.add_to_project(projectMember2, project)

    # Create some non-member
    User.generate!

    assert_equal [User.current, projectMember1, projectMember2].map(&:id).sort, ListUser::getUsersAllowedToDisplay.map(&:id).sort
  end
end
