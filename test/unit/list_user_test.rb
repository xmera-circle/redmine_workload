# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class ListUserTest < ActiveSupport::TestCase
  include WorkloadsHelper

  fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
           :users, :issue_statuses, :enumerations, :roles

  def teardown
    User.current = nil
  end

  test 'open_issues_for_users returns empty list if no users given' do
    assert_equal [], ListUser.open_issues_for_users([])
  end

  test 'open_issues_for_users returns only issues of interesting users' do
    user1 = User.generate!
    user2 = User.generate!

    project1 = Project.generate!

    User.add_to_project(user1, project1, Role.find_by_name('Manager'))
    User.add_to_project(user2, project1, Role.find_by_name('Manager'))

    issue1 = Issue.generate!(assigned_to: user1,
                             status: IssueStatus.find(1), # New, not closed
                             project: project1)

    issue2 = Issue.generate!(assigned_to: user2,
                             status: IssueStatus.find(1), # New, not closed
                             project: project1)

    assert_equal [issue2], ListUser.open_issues_for_users([user2])
  end

  test 'open_issues_for_users returns only open issues' do
    user = User.generate!
    project1 = Project.generate!

    User.add_to_project(user, project1, Role.find_by_name('Manager'))

    issue1 = Issue.generate!(assigned_to: user,
                             # :status => IssueStatus.find(6), # rejected, closed
                             # :status_id => 2,
                             project: project1)
    issue1.status_id = 2
    issue1.status.update! is_closed: true
    issue1.save!

    issue2 = Issue.generate!(assigned_to: user,
                             # :status => IssueStatus.find(1), # New, not closed
                             status_id: 1,
                             project: project1)

    assert_equal [issue2], ListUser.open_issues_for_users([user])
  end

  test 'getMonthsBetween returns [] if last day after first day' do
    first_day = Date.new(2012, 3, 29)
    last_day = Date.new(2012, 3, 28)

    assert_equal [], DateTools.months_in_time_span(first_day..last_day)
  end

  test 'getMonthsBetween returns [3] if both days in march 2012 and equal' do
    first_day = Date.new(2012, 3, 27)
    last_day = Date.new(2012, 3, 27)

    expected = [3]
    current = months_numbers_in_time_span(first_day, last_day)
    assert_equal expected, current.flatten.uniq
  end

  test 'months_in_time_span returns [3] if both days in march 2012 and different' do
    first_day = Date.new(2012, 3, 27)
    last_day = Date.new(2012, 3, 28)

    expected = [3]
    current = months_numbers_in_time_span(first_day, last_day)
    assert_equal expected, current.flatten.uniq
  end

  test 'months_in_time_span returns [3, 4, 5] if first day in march and last day in may' do
    first_day = Date.new(2012, 3, 31)
    last_day = Date.new(2012, 5, 1)

    expected = [3, 4, 5]
    current = months_numbers_in_time_span(first_day, last_day)

    assert_equal expected, current.flatten.uniq
  end

  test 'getMonthsBetween returns correct result timespan overlaps year boundary' do
    first_day = Date.new(2011, 3, 3)
    last_day = Date.new(2012, 5, 1)

    expected = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2]
    current = months_numbers_in_time_span(first_day, last_day)
    assert_equal expected, current.flatten.uniq
  end

  test 'hours_for_issue_per_day returns {} if time span empty' do
    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 31),
      due_date: Date.new(2013, 6, 2),
      estimated_hours: 10.0,
      done_ratio: 10
    )

    first_day = Date.new(2013, 5, 31)
    last_day = Date.new(2013, 5, 29)

    assert_issue_times_hash_equals({}, ListUser.send(:hours_for_issue_per_day,
                                                     issue,
                                                     first_day..last_day,
                                                     first_day))
  end

  test 'hours_for_issue_per_day works if issue is completely in given time span and nothing done' do
    define_saturday_sunday_and_wednesday_as_holiday

    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 31), # A Friday
      due_date: Date.new(2013, 6, 2),    # A Sunday
      estimated_hours: 10.0,
      done_ratio: 0
    )

    first_day = Date.new(2013, 5, 31) # A Friday
    last_day = Date.new(2013, 6, 3)   # A Monday

    expected_result = {
      Date.new(2013, 5, 31) => {
        hours: 10.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      Date.new(2013, 6, 1) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      },
      Date.new(2013, 6, 2) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      },
      Date.new(2013, 6, 3) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: false
      }
    }

    assert_issue_times_hash_equals expected_result,
                                   ListUser.send(:hours_for_issue_per_day,
                                                 issue,
                                                 first_day..last_day,
                                                 first_day)
  end

  test 'hours_for_issue_per_day works if issue lasts after time span and done_ratio > 0' do
    define_saturday_sunday_and_wednesday_as_holiday

    # 30 hours still need to be done, 3 working days until issue is finished.
    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 28), # A Tuesday
      due_date: Date.new(2013, 6, 1),    # A Saturday
      estimated_hours: 40.0,
      done_ratio: 25
    )

    first_day = Date.new(2013, 5, 27) # A Monday, before issue starts
    last_day = Date.new(2013, 5, 30) # Thursday, before issue ends

    expected_result = {
      # Monday, no holiday, before issue starts.
      Date.new(2013, 5, 27) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: false
      },
      # Tuesday, no holiday, issue starts here
      Date.new(2013, 5, 28) => {
        hours: 10.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      # Wednesday, holiday
      Date.new(2013, 5, 29) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      },
      # Thursday, no holiday, last day of time span
      Date.new(2013, 5, 30) => {
        hours: 10.0,
        active: true,
        noEstimate: false,
        holiday: false
      }
    }

    assert_issue_times_hash_equals expected_result,
                                   ListUser.send(:hours_for_issue_per_day,
                                                 issue,
                                                 first_day..last_day,
                                                 first_day)
  end

  test 'hours_for_issue_per_day works if issue starts before time span' do
    define_saturday_sunday_and_wednesday_as_holiday

    # 36 hours still need to be done, 2 working days until issue is due.
    # One day has already passed with 10% done.
    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 28), # A Thursday
      due_date: Date.new(2013, 6, 1),    # A Saturday
      estimated_hours: 40.0,
      done_ratio: 10
    )

    first_day = Date.new(2013, 5, 29) # A Wednesday, before issue starts
    last_day = Date.new(2013, 6, 1)   # Saturday, before issue ends

    expected_result = {
      # Wednesday, holiday, first day of time span.
      Date.new(2013, 5, 29) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      },
      # Thursday, no holiday
      Date.new(2013, 5, 30) => {
        hours: 18.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      # Friday, no holiday
      Date.new(2013, 5, 31) => {
        hours: 18.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      # Saturday, holiday, last day of time span
      Date.new(2013, 6, 1) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      }
    }

    assert_issue_times_hash_equals expected_result,
                                   ListUser.send(:hours_for_issue_per_day,
                                                 issue,
                                                 first_day..last_day,
                                                 first_day)
  end

  test 'hours_for_issue_per_day works if issue completely before time span' do
    define_saturday_sunday_and_wednesday_as_holiday

    # 10 hours still need to be done, but issue is overdue. Remaining hours need
    # to be put on first working day of time span.
    issue = Issue.generate!(
      start_date: nil, # No start date
      due_date: Date.new(2013, 6, 1), # A Saturday
      estimated_hours: 100.0,
      done_ratio: 90
    )

    first_day = Date.new(2013, 6, 2)  # Sunday, after issue due date
    last_day = Date.new(2013, 6, 4)   # Tuesday

    expected_result = {
      # Sunday, holiday.
      Date.new(2013, 6, 2) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: true
      },
      # Monday, no holiday, first working day in time span.
      Date.new(2013, 6, 3) => {
        hours: 10.0,
        active: false,
        noEstimate: false,
        holiday: false
      },
      # Tuesday, no holiday
      Date.new(2013, 6, 4) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: false
      }
    }

    assert_issue_times_hash_equals expected_result,
                                   ListUser.send(:hours_for_issue_per_day,
                                                 issue,
                                                 first_day..last_day,
                                                 first_day)
  end

  test 'hours_for_issue_per_day works if issue has no due date' do
    define_saturday_sunday_and_wednesday_as_holiday

    # 10 hours still need to be done.
    issue = Issue.generate!(
      start_date: Date.new(2013, 6, 3), # A Tuesday
      due_date: nil,
      estimated_hours: 100.0,
      done_ratio: 90
    )

    first_day = Date.new(2013, 6, 2)  # Sunday
    last_day = Date.new(2013, 6, 4)   # Tuesday

    expected_result = {
      # Sunday, holiday.
      Date.new(2013, 6, 2) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: true
      },
      # Monday, no holiday, first working day in time span.
      Date.new(2013, 6, 3) => {
        hours: 0.0,
        active: true,
        noEstimate: true,
        holiday: false
      },
      # Tuesday, no holiday
      Date.new(2013, 6, 4) => {
        hours: 0.0,
        active: true,
        noEstimate: true,
        holiday: false
      }
    }

    assert_issue_times_hash_equals expected_result,
                                   ListUser.send(:hours_for_issue_per_day,
                                                 issue,
                                                 first_day..last_day,
                                                 first_day)
  end

  test 'hours_for_issue_per_day works if issue has no start date' do
    define_saturday_sunday_and_wednesday_as_holiday

    # 10 hours still need to be done.
    issue = Issue.generate!(
      start_date: nil,
      due_date: Date.new(2013, 6, 3),
      estimated_hours: 100.0,
      done_ratio: 90
    )

    first_day = Date.new(2013, 6, 2)  # Sunday
    last_day = Date.new(2013, 6, 4)   # Tuesday

    expected_result = {
      # Sunday, holiday.
      Date.new(2013, 6, 2) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      },
      # Monday, no holiday, first working day in time span.
      Date.new(2013, 6, 3) => {
        hours: 0.0,
        active: true,
        noEstimate: true,
        holiday: false
      },
      # Tuesday, no holiday
      Date.new(2013, 6, 4) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: false
      }
    }

    assert_issue_times_hash_equals expected_result,
                                   ListUser.send(:hours_for_issue_per_day,
                                                 issue,
                                                 first_day..last_day,
                                                 first_day)
  end

  test 'hours_for_issue_per_day works if in time span and issue overdue' do
    define_saturday_sunday_and_wednesday_as_holiday

    # 10 hours still need to be done, but issue is overdue. Remaining hours need
    # to be put on first working day of time span.
    issue = Issue.generate!(
      start_date: nil, # No start date
      due_date: Date.new(2013, 6, 1), # A Saturday
      estimated_hours: 100.0,
      done_ratio: 90
    )

    first_day = Date.new(2013, 5, 30)  # Thursday
    last_day = Date.new(2013, 6, 4)    # Tuesday
    today = Date.new(2013, 6, 2)      # After issue end

    expected_result = {
      # Thursday, in the past.
      Date.new(2013, 5, 30) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      # Friday, in the past.
      Date.new(2013, 5, 31) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      # Saturday, holiday, in the past.
      Date.new(2013, 6, 1) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      },
      # Sunday, holiday.
      Date.new(2013, 6, 2) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: true
      },
      # Monday, no holiday, first working day in time span.
      Date.new(2013, 6, 3) => {
        hours: 10.0,
        active: false,
        noEstimate: false,
        holiday: false
      },
      # Tuesday, no holiday
      Date.new(2013, 6, 4) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: false
      }
    }

    assert_issue_times_hash_equals expected_result,
                                   ListUser.send(:hours_for_issue_per_day,
                                                 issue,
                                                 first_day..last_day,
                                                 today)
  end

  test 'hours_for_issue_per_day works if issue is completely in given time span, but has started' do
    define_saturday_sunday_and_wednesday_as_holiday

    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 31), # A Friday
      due_date: Date.new(2013, 6, 4),    # A Tuesday
      estimated_hours: 10.0,
      done_ratio: 0
    )

    first_day = Date.new(2013, 5, 31) # A Friday
    last_day = Date.new(2013, 6, 5)   # A Wednesday
    today = Date.new(2013, 6, 2)     # A Sunday

    expected_result = {
      # Friday
      Date.new(2013, 5, 31) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      # Saturday
      Date.new(2013, 6, 1) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      },
      # Sunday
      Date.new(2013, 6, 2) => {
        hours: 0.0,
        active: true,
        noEstimate: false,
        holiday: true
      },
      # Monday
      Date.new(2013, 6, 3) => {
        hours: 5.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      # Tuesday
      Date.new(2013, 6, 4) => {
        hours: 5.0,
        active: true,
        noEstimate: false,
        holiday: false
      },
      # Wednesday
      Date.new(2013, 6, 5) => {
        hours: 0.0,
        active: false,
        noEstimate: false,
        holiday: true
      }
    }

    assert_issue_times_hash_equals expected_result,
                                   ListUser.send(:hours_for_issue_per_day,
                                                 issue,
                                                 first_day..last_day,
                                                 today)
  end

  test 'hours_per_user_issue_and_day returns correct structure' do
    user = User.generate!

    project1 = Project.generate!
    project2 = Project.generate!

    User.add_to_project(user, project1, Role.find_by_name('Manager'))
    User.add_to_project(user, project2, Role.find_by_name('Manager'))

    issue1 = Issue.generate!(
      assigned_to: user,
      start_date: Date.new(2013, 5, 31), # A Friday
      due_date: Date.new(2013, 6, 4),    # A Tuesday
      estimated_hours: 10.0,
      done_ratio: 50,
      status: IssueStatus.find(1), # New, not closed
      project: project1
    )

    issue2 = Issue.generate!(
      assigned_to: user,
      start_date: Date.new(2013, 6, 3), # A Friday
      due_date: Date.new(2013, 6, 6), # A Tuesday
      estimated_hours: 30.0,
      done_ratio: 50,
      status: IssueStatus.find(1), # New, not closed
      project: project2
    )

    first_day = Date.new(2013, 5, 25)
    last_day = Date.new(2013, 6, 4)
    today = Date.new(2013, 5, 31)

    workloadData = ListUser.hours_per_user_issue_and_day(Issue.assigned_to(user).to_a,
                                                         first_day..last_day,
                                                         today)

    assert workloadData.key?(user)

    # Check structure returns the 4 elements :overdue_hours, :overdue_number, :total, :invisible
    # AND 2 Projects
    assert_equal 6, workloadData[user].keys.count
    assert workloadData[user].key?(:overdue_hours)
    assert workloadData[user].key?(:overdue_number)
    assert workloadData[user].key?(:total)
    assert workloadData[user].key?(:invisible)
    assert workloadData[user].key?(project1)
    assert workloadData[user].key?(project2)
  end

  test 'estimated_time_for_issue works for issue without children.' do
    issue = Issue.generate!(estimated_hours: 13.2)
    assert_in_delta 13.2, ListUser.send(:estimated_time_for_issue, issue), 1e-4
  end

  test 'estimated_time_for_issue works for issue with children.' do
    parent = Issue.generate!(estimated_hours: 3.6)
    child1 = Issue.generate!(estimated_hours: 5.0, parent_issue_id: parent.id, done_ratio: 90)
    child2 = Issue.generate!(estimated_hours: 9.0, parent_issue_id: parent.id)

    # Force parent to reload so the data from the children is incorporated.
    parent.reload

    assert_in_delta 0.0, ListUser.send(:estimated_time_for_issue, parent), 1e-4
    assert_in_delta 0.5, ListUser.send(:estimated_time_for_issue, child1), 1e-4
    assert_in_delta 9.0, ListUser.send(:estimated_time_for_issue, child2), 1e-4
  end

  test 'estimated_time_for_issue works for issue with grandchildren.' do
    parent = Issue.generate!(estimated_hours: 4.5)
    child = Issue.generate!(estimated_hours: 5.0, parent_issue_id: parent.id)
    grandchild = Issue.generate!(estimated_hours: 9.0, parent_issue_id: child.id, done_ratio: 40)

    # Force parent and child to reload so the data from the children is
    # incorporated.
    parent.reload
    child.reload

    assert_in_delta 0.0, ListUser.send(:estimated_time_for_issue, parent), 1e-4
    assert_in_delta 0.0, ListUser.send(:estimated_time_for_issue, child), 1e-4
    assert_in_delta 5.4, ListUser.send(:estimated_time_for_issue, grandchild), 1e-4
  end

  test 'load_class_for_hours returns "none" for workloads below threshold for low workload' do
    Setting['plugin_redmine_workload']['threshold_lowload_min'] = 0.1
    Setting['plugin_redmine_workload']['threshold_normalload_min'] = 5.0
    Setting['plugin_redmine_workload']['threshold_highload_min'] = 7.0

    assert_equal 'none', load_class_for_hours(0.05)
  end

  test 'load_class_for_hours returns "low" for workloads between thresholds for low and normal workload' do
    Setting['plugin_redmine_workload']['threshold_lowload_min'] = 0.1
    Setting['plugin_redmine_workload']['threshold_normalload_min'] = 5.0
    Setting['plugin_redmine_workload']['threshold_highload_min'] = 7.0

    assert_equal 'low', load_class_for_hours(3.5)
  end

  test 'load_class_for_hours returns "normal" for workloads between thresholds for normal and high workload' do
    Setting['plugin_redmine_workload']['threshold_lowload_min'] = 0.1
    Setting['plugin_redmine_workload']['threshold_normalload_min'] = 2.0
    Setting['plugin_redmine_workload']['threshold_highload_min'] = 7.0

    assert_equal 'normal', load_class_for_hours(3.5)
  end

  test 'load_class_for_hours returns "high" for workloads above threshold for high workload' do
    Setting['plugin_redmine_workload']['threshold_lowload_min'] = 0.1
    Setting['plugin_redmine_workload']['threshold_normalload_min'] = 2.0
    Setting['plugin_redmine_workload']['threshold_highload_min'] = 7.0

    assert_equal 'high', load_class_for_hours(10.5)
  end

  test 'users_allowed_to_display returns an empty array if the current user is anonymus.' do
    users = UserSelection.new(user: User.anonymous)

    assert_equal [], users.allowed_to_display
  end

  test 'users_allowed_to_display returns only the user himself if user has no role assigned.' do
    user = User.generate!
    users = UserSelection.new(user: user)
    assert_equal [user].map(&:id).sort, users.allowed_to_display.map(&:id).sort
  end

  test 'users_allowed_to_display returns all users if the current user is a admin.' do
    user = User.generate!(admin: true)
    users = UserSelection.new(user: user)
    # Make this user an admin (can't do it in the attributes?!?)

    assert_equal User.active.map(&:id).sort, users.allowed_to_display.map(&:id).sort
  end

  test 'users_allowed_to_display returns exactly project members if user has right to see workload of project members.' do
    user =  User.generate!
    project = Project.generate!
    project.enable_module! :Workload

    project_manager_role = Role.generate!(name: 'Project manager',
                                          permissions: [:view_project_workload])

    User.add_to_project(user, project, project_manager_role)

    project_member1 = User.generate!
    User.add_to_project(project_member1, project)
    project_member2 = User.generate!
    User.add_to_project(project_member2, project)

    # Create some non-member
    User.generate!
    users = UserSelection.new(user: user)
    assert_equal [user, project_member1, project_member2].map(&:id).sort,
                 users.allowed_to_display.map(&:id).sort
  end

  private

  def months_numbers_in_time_span(first_day, last_day)
    DateTools.months_in_time_span(first_day..last_day).map do |span|
      [span[:first_day].month, span[:last_day].month]
    end
  end

  # Set Saturday, Sunday and Wednesday to be a holiday, all others to be a
  # working day.
  def define_saturday_sunday_and_wednesday_as_holiday
    Setting['plugin_redmine_workload']['general_workday_monday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_tuesday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_wednesday'] = ''
    Setting['plugin_redmine_workload']['general_workday_thursday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_friday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_saturday'] = ''
    Setting['plugin_redmine_workload']['general_workday_sunday'] = ''
  end

  def assert_issue_times_hash_equals(expected, actual)
    assert expected.is_a?(Hash), 'Expected is no hash.'
    assert actual.is_a?(Hash),   'Actual is no hash.'

    assert_equal expected.keys.sort, actual.keys.sort, 'Date keys are not equal'

    expected.keys.sort.each do |day|
      assert expected[day].is_a?(Hash), "Expected is no hashon day #{day}."
      assert actual[day].is_a?(Hash),   "Actual is no hash on day #{day}."

      assert expected[day].key?(:hours),      "On day #{day}, expected has no key :hours"
      assert expected[day].key?(:active),     "On day #{day}, expected has no key :active"
      assert expected[day].key?(:noEstimate), "On day #{day}, expected has no key :noEstimate"
      assert expected[day].key?(:holiday),    "On day #{day}, expected has no key :holiday"

      assert actual[day].key?(:hours),        "On day #{day}, actual has no key :hours"
      assert actual[day].key?(:active),       "On day #{day}, actual has no key :active"
      assert actual[day].key?(:noEstimate),   "On day #{day}, actual has no key :noEstimate"
      assert actual[day].key?(:holiday),      "On day #{day}, actual has no key :holiday"

      assert_in_delta expected[day][:hours],   actual[day][:hours], 1e-4, "On day #{day}, hours wrong: #{actual[day][:hours]}"
      assert_equal expected[day][:active],     actual[day][:active],      "On day #{day}, active wrong"
      assert_equal expected[day][:noEstimate], actual[day][:noEstimate],  "On day #{day}, noEstimate wrong"
      assert_equal expected[day][:holiday],    actual[day][:holiday],     "On day #{day}, holiday wrong"
    end
  end
end
