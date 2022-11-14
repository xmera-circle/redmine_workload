# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class UserWorkloadTest < ActiveSupport::TestCase
  include WorkloadsHelper
  include WlUserDataDefaults

  fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
           :users, :issue_statuses, :enumerations, :roles

  def setup
    @manager = roles :roles_001
    @jsmith = users :users_002
    @cap = WlDayCapacity.new(assignee: @jsmith)
  end

  def teardown
    User.current = nil
  end

  test 'should respond to by_user' do
    first_day = Date.new(2011, 3, 3)
    last_day = Date.new(2012, 5, 1)
    workload = UserWorkload.new(assignees: [],
                                time_span: first_day..last_day,
                                today: first_day + 1)
    assert workload.by_user
  end

  test 'open_issues_for_users returns empty list if no users given' do
    first_day = Date.new(2011, 3, 3)
    last_day = Date.new(2012, 5, 1)
    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day + 1)
    assert_equal [], user_workload.issues
  end

  test 'open_issues_for_users returns only issues of given users' do
    user1 = User.generate!
    user2 = User.generate!

    project1 = Project.generate!

    User.add_to_project(user1, project1, @manager)
    User.add_to_project(user2, project1, @manager)

    Issue.generate!(assigned_to: user1,
                    status: IssueStatus.find(1), # New, not closed
                    project: project1)

    issue2 = Issue.generate!(assigned_to: user2,
                             status: IssueStatus.find(1), # New, not closed
                             project: project1)

    first_day = Date.new(2011, 3, 3)
    last_day = Date.new(2012, 5, 1)
    user_workload = UserWorkload.new(assignees: [user2],
                                     time_span: first_day..last_day,
                                     today: first_day + 1)
    assert_equal [issue2], user_workload.issues
  end

  test 'open_issues_for_users returns only open issues' do
    user = User.generate!
    project1 = Project.generate!

    User.add_to_project(user, project1, @manager)

    issue1 = Issue.generate!(assigned_to: user,
                             project: project1)
    issue1.status_id = 2 # rejected
    issue1.status.update! is_closed: true
    issue1.save!

    issue2 = Issue.generate!(assigned_to: user,
                             status_id: 1, # new
                             project: project1)
    first_day = Date.new(2011, 3, 3)
    last_day = Date.new(2012, 5, 1)
    user_workload = UserWorkload.new(assignees: [user],
                                     time_span: first_day..last_day,
                                     today: first_day + 1)

    assert_equal [issue2], user_workload.issues
  end

  test 'counts unscheduled issues and hours on project and user level' do
    user = User.generate!
    project1 = Project.generate!

    User.add_to_project(user, project1, @manager)

    issue1 = Issue.generate!(assigned_to: user,
                             project: project1)
    issue1.status_id = 2 # rejected
    issue1.status.update! is_closed: true
    issue1.save!

    Issue.generate!(assigned_to: user,
                    status_id: 1, # new
                    estimated_hours: 5.0,
                    project: project1)
    first_day = Date.new(2011, 3, 3)
    last_day = Date.new(2012, 5, 1)
    user_workload = UserWorkload.new(assignees: [user],
                                     time_span: first_day..last_day,
                                     today: first_day + 1)

    data = user_workload.by_user
    assert_equal 1, data[user][:unscheduled_number]
    assert_equal 5.0, data[user][:unscheduled_hours]
    assert_equal 1, data[user][project1][:unscheduled_number]
    assert_equal 5.0, data[user][project1][:unscheduled_hours]
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

    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: last_day)

    assert_issue_times_hash_equals({}, user_workload.send(:hours_for_issue_per_day,
                                                          issue, @cap, @jsmith))
  end

  test 'hours_for_issue_per_day works if issue is completely in given time span and nothing done' do
    define_saturday_sunday_and_wednesday_as_holiday

    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 31), # A Friday
      due_date: Date.new(2013, 6, 2), # A Sunday
      estimated_hours: 10.0,
      done_ratio: 0
    )

    first_day = Date.new(2013, 5, 31) # A Friday
    last_day = Date.new(2013, 6, 3) # A Monday

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

    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)

    assert_issue_times_hash_equals expected_result,
                                   user_workload.send(:hours_for_issue_per_day,
                                                      issue, @cap, @jsmith)
  end

  test 'hours_for_issue_per_day works if issue lasts after time span and done_ratio > 0' do
    define_saturday_sunday_and_wednesday_as_holiday

    # 30 hours still need to be done, 3 working days until issue is finished.
    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 28), # A Tuesday
      due_date: Date.new(2013, 6, 1), # A Saturday
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

    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)

    assert_issue_times_hash_equals expected_result,
                                   user_workload.send(:hours_for_issue_per_day,
                                                      issue, @cap, @jsmith)
  end

  test 'hours_for_issue_per_day works if issue starts before time span' do
    define_saturday_sunday_and_wednesday_as_holiday

    # 36 hours still need to be done, 2 working days until issue is due.
    # One day has already passed with 10% done.
    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 28), # A Thursday
      due_date: Date.new(2013, 6, 1), # A Saturday
      estimated_hours: 40.0,
      done_ratio: 10
    )

    first_day = Date.new(2013, 5, 29) # A Wednesday, before issue starts
    last_day = Date.new(2013, 6, 1) # Saturday, before issue ends

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

    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)

    assert_issue_times_hash_equals expected_result,
                                   user_workload.send(:hours_for_issue_per_day,
                                                      issue, @cap, @jsmith)
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

    first_day = Date.new(2013, 6, 2) # Sunday, after issue due date
    last_day = Date.new(2013, 6, 4) # Tuesday

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
    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)

    assert_issue_times_hash_equals expected_result,
                                   user_workload.send(:hours_for_issue_per_day,
                                                      issue, @cap, @jsmith)
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

    first_day = Date.new(2013, 6, 2) # Sunday
    last_day = Date.new(2013, 6, 4) # Tuesday

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

    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)

    assert_issue_times_hash_equals expected_result,
                                   user_workload.send(:hours_for_issue_per_day,
                                                      issue, @cap, @jsmith)
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

    first_day = Date.new(2013, 6, 2) # Sunday
    last_day = Date.new(2013, 6, 4) # Tuesday

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
    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)

    assert_issue_times_hash_equals expected_result,
                                   user_workload.send(:hours_for_issue_per_day,
                                                      issue, @cap, @jsmith)
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

    first_day = Date.new(2013, 5, 30) # Thursday
    last_day = Date.new(2013, 6, 4) # Tuesday
    today = Date.new(2013, 6, 2) # After issue end

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
    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: today)

    assert_issue_times_hash_equals expected_result,
                                   user_workload.send(:hours_for_issue_per_day,
                                                      issue, @cap, @jsmith)
  end

  test 'hours_for_issue_per_day works if issue is completely in given time span, but has started' do
    define_saturday_sunday_and_wednesday_as_holiday

    issue = Issue.generate!(
      start_date: Date.new(2013, 5, 31), # A Friday
      due_date: Date.new(2013, 6, 4), # A Tuesday
      estimated_hours: 10.0,
      done_ratio: 0
    )

    first_day = Date.new(2013, 5, 31) # A Friday
    last_day = Date.new(2013, 6, 5) # A Wednesday
    today = Date.new(2013, 6, 2) # A Sunday

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
    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: today)

    assert_issue_times_hash_equals expected_result,
                                   user_workload.send(:hours_for_issue_per_day,
                                                      issue, @cap, @jsmith)
  end

  test 'hours_per_user_issue_and_day returns correct structure' do
    user = User.generate!
    manager = roles :roles_001

    project1 = Project.generate!
    project2 = Project.generate!

    User.add_to_project(user, project1, manager)
    User.add_to_project(user, project2, manager)

    Issue.generate!(
      assigned_to: user,
      start_date: Date.new(2013, 5, 31), # A Friday
      due_date: Date.new(2013, 6, 4),    # A Tuesday
      estimated_hours: 10.0,
      done_ratio: 50,
      status: IssueStatus.find(1), # New, not closed
      project: project1
    )

    Issue.generate!(
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

    user_workload = UserWorkload.new(assignees: [user],
                                     time_span: first_day..last_day,
                                     today: today,
                                     issues: Issue.assigned_to(user).to_a)

    workload_data = user_workload.hours_per_user_issue_and_day

    assert workload_data.key?(user)

    # Check structure returns the 6 elements :overdue_hours, :overdue_number,
    # :unscheduled_number, :unscheduled_hours, :total, :invisible
    # AND 2 Projects
    assert_equal 8, workload_data[user].keys.count
    assert workload_data[user].key?(:overdue_hours)
    assert workload_data[user].key?(:overdue_number)
    assert workload_data[user].key?(:unscheduled_number)
    assert workload_data[user].key?(:unscheduled_hours)
    assert workload_data[user].key?(:total)
    assert workload_data[user].key?(:invisible)
    assert workload_data[user].key?(project1)
    assert workload_data[user].key?(project2)
  end

  test 'estimated_time_for_issue works for issue without children.' do
    issue = Issue.generate!(estimated_hours: 13.2)
    first_day = Date.new(2013, 5, 25)
    last_day = Date.new(2013, 6, 4)
    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)
    assert_in_delta 13.2, user_workload.send(:estimated_time_for_issue, issue), 1e-4
  end

  test 'estimated_time_for_issue works for issue with children.' do
    parent = Issue.generate!(estimated_hours: 3.6)
    child1 = Issue.generate!(estimated_hours: 5.0, parent_issue_id: parent.id, done_ratio: 90)
    child2 = Issue.generate!(estimated_hours: 9.0, parent_issue_id: parent.id)

    # Force parent to reload so the data from the children is incorporated.
    parent.reload
    first_day = Date.new(2013, 5, 25)
    last_day = Date.new(2013, 6, 4)
    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)

    assert_in_delta 0.0, user_workload.send(:estimated_time_for_issue, parent), 1e-4
    assert_in_delta 0.5, user_workload.send(:estimated_time_for_issue, child1), 1e-4
    assert_in_delta 9.0, user_workload.send(:estimated_time_for_issue, child2), 1e-4
  end

  test 'estimated_time_for_issue works for issue with grandchildren.' do
    parent = Issue.generate!(estimated_hours: 4.5)
    child = Issue.generate!(estimated_hours: 5.0, parent_issue_id: parent.id)
    grandchild = Issue.generate!(estimated_hours: 9.0, parent_issue_id: child.id, done_ratio: 40)

    # Force parent and child to reload so the data from the children is
    # incorporated.
    parent.reload
    child.reload
    first_day = Date.new(2013, 5, 25)
    last_day = Date.new(2013, 6, 4)
    user_workload = UserWorkload.new(assignees: [],
                                     time_span: first_day..last_day,
                                     today: first_day)

    assert_in_delta 0.0, user_workload.send(:estimated_time_for_issue, parent), 1e-4
    assert_in_delta 0.0, user_workload.send(:estimated_time_for_issue, child), 1e-4
    assert_in_delta 5.4, user_workload.send(:estimated_time_for_issue, grandchild), 1e-4
  end

  test 'load_class_for_hours can handle missing thresholds' do
    assert_equal 'high', load_class_for_hours(0.05,
                                              nil,
                                              nil,
                                              nil)
  end

  test 'load_class_for_hours returns "none" for workloads below threshold for low workload' do
    settings['threshold_lowload_min'] = 0.1
    settings['threshold_normalload_min'] = 5.0
    settings['threshold_highload_min'] = 7.0

    assert_equal 'none', load_class_for_hours(0.05,
                                              settings['threshold_lowload_min'],
                                              settings['threshold_normalload_min'],
                                              settings['threshold_highload_min'])
  end

  test 'load_class_for_hours returns "low" for workloads between thresholds for low and normal workload' do
    settings['threshold_lowload_min'] = 0.1
    settings['threshold_normalload_min'] = 5.0
    settings['threshold_highload_min'] = 7.0

    assert_equal 'low', load_class_for_hours(3.5,
                                             settings['threshold_lowload_min'],
                                             settings['threshold_normalload_min'],
                                             settings['threshold_highload_min'])
  end

  test 'load_class_for_hours returns "normal" for workloads between thresholds for normal and high workload' do
    settings['threshold_lowload_min'] = 0.1
    settings['threshold_normalload_min'] = 2.0
    settings['threshold_highload_min'] = 7.0

    assert_equal 'normal', load_class_for_hours(3.5,
                                                settings['threshold_lowload_min'],
                                                settings['threshold_normalload_min'],
                                                settings['threshold_highload_min'])
  end

  test 'load_class_for_hours returns "high" for workloads above threshold for high workload' do
    settings['threshold_lowload_min'] = 0.1
    settings['threshold_normalload_min'] = 2.0
    settings['threshold_highload_min'] = 7.0

    assert_equal 'high', load_class_for_hours(10.5,
                                              settings['threshold_lowload_min'],
                                              settings['threshold_normalload_min'],
                                              settings['threshold_highload_min'])
  end

  private

  # Set Saturday, Sunday and Wednesday to be a holiday, all others to be a
  # working day.
  def define_saturday_sunday_and_wednesday_as_holiday
    settings['general_workday_monday'] = 'checked'
    settings['general_workday_tuesday'] = 'checked'
    settings['general_workday_wednesday'] = ''
    settings['general_workday_thursday'] = 'checked'
    settings['general_workday_friday'] = 'checked'
    settings['general_workday_saturday'] = ''
    settings['general_workday_sunday'] = ''
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
