# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WlNationalHolidayTest < ActiveSupport::TestCase
    fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
            :users, :issue_statuses, :enumerations, :roles

    setup do
      # reset default settings
      Setting['plugin_redmine_workload']['general_workday_monday'] = 'checked'
      Setting['plugin_redmine_workload']['general_workday_tuesday'] = 'checked'
      Setting['plugin_redmine_workload']['general_workday_wednesday'] = 'checked'
      Setting['plugin_redmine_workload']['general_workday_thursday'] = 'checked'
      Setting['plugin_redmine_workload']['general_workday_friday'] = 'checked'
      Setting['plugin_redmine_workload']['general_workday_saturday'] = ''
      Setting['plugin_redmine_workload']['general_workday_sunday'] = ''
    end

    test 'single holiday' do
      holiday = WlNationalHoliday.new(start: Date.new(2017, 5, 30), end: Date.new(2017, 5, 30),
                                      reason: 'Test Holiday')

    assert holiday.save, 'Holiday could not be created or saved!'
    assert RedmineWorkload::WlDateTools.holiday?(holiday[:start]), '2017-05-30 should be a holiday!'
    assert holiday.destroy, 'Holiday could not be deleted!'
  end

    test 'check holiday is day off' do
      holiday = WlNationalHoliday.new(start: Date.new(2017, 5, 30), end: Date.new(2017, 5, 31),
                                      reason: 'Test Holiday with 2 days')
      holiday.save

    assert holiday.save, 'Holiday could not be created or saved!'
    assert RedmineWorkload::WlDateTools.holiday?(holiday[:start]), '2017-05-30 should be a holiday!'
    assert RedmineWorkload::WlDateTools.holiday?(holiday[:end]), '2017-05-31 should be a holiday!'
  end

    test 'holiday is not workday' do
      first_day = Date.new(2017, 5, 15)
      last_day = Date.new(2017, 5, 19)
      user = User.generate!
      cap = WlDayCapacity.new(assignee: user)

      issue = Issue.generate!(
        start_date: first_day,
        due_date: last_day,
        estimated_hours: 40.0,
        done_ratio: 50
      )
      user_workload = UserWorkload.new(assignees: [],
                                      time_span: first_day..last_day,
                                      today: first_day,
                                      issues: [issue])

      holiday1 = WlNationalHoliday.new(start: Date.new(2017, 5, 19), end: Date.new(2017, 5, 19),
                                      reason: 'Test Holiday')
      holiday2 = WlNationalHoliday.new(start: Date.new(2017, 5, 16), end: Date.new(2017, 5, 17),
                                      reason: 'Test Holiday with 2 days')
      holiday1.save
      holiday2.save

    result = RedmineWorkload::WlDateTools.working_days_in_time_span(first_day..last_day, user).to_a

      assert_equal [first_day, last_day - 1], result, 'Result should only bring 2 workdays!'

      result = user_workload.send(:hours_for_issue_per_day, issue, cap, user)

      assert_equal 10.0, result[first_day][:hours], 'Workday should have 10h load!'
      assert_equal 0.0, result[first_day + 1][:hours], 'Workday should be day off for holiday!' # holiday2[:start]
      assert_equal 0.0, result[first_day + 2][:hours], 'Workday should be day off for holiday!' # holiday2[:end]
      assert_equal 10.0, result[first_day + 3][:hours], 'Workday should have 10h load!'
      assert_equal 0.0, result[first_day + 4][:hours], 'Workday should be day off for holiday!' # holiday1[:start]
    end
  end
end
