# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class RedmineWorkload::WlDateToolsTest < ActiveSupport::TestCase
    include RedmineWorkload::WorkloadObjectHelper

    def setup
      @user = User.generate!
    end

    test 'working_days_in_time_span works if start and end day are equal and no holiday.' do
      # Set friday to be a working day.
      Setting['plugin_redmine_workload']['general_workday_friday'] = 'checked'

    date = Date.new(2005, 12, 30) # A friday
    assert_equal Set.new([date]), RedmineWorkload::WlDateTools.working_days_in_time_span(date..date, @user, no_cache: true)
  end

    test 'working_days_in_time_span works if start and end day are equal and a holiday.' do
      # Set friday to be a holiday.
      Setting['plugin_redmine_workload']['general_workday_friday'] = ''

    date = Date.new(2005, 12, 30) # A friday
    assert_equal Set.new, RedmineWorkload::WlDateTools.working_days_in_time_span(date..date, @user, no_cache: true)
  end

  test 'working_days_in_time_span works if start day before end day.' do
    start_date = Date.new(2005, 12, 30) # A friday
    end_date = Date.new(2005, 12, 28) # A wednesday
    assert_equal Set.new, RedmineWorkload::WlDateTools.working_days_in_time_span(start_date..end_date, @user, no_cache: true)
  end

    test 'working_days_in_time_span works if both days follow each other and are holidays.' do
      # Set wednesday and thursday to be a holiday.
      Setting['plugin_redmine_workload']['general_workday_wednesday'] = ''
      Setting['plugin_redmine_workload']['general_workday_thursday'] = ''

    start_date = Date.new(2005, 12, 28) # A wednesday
    end_date = Date.new(2005, 12, 29) # A thursday
    assert_equal Set.new, RedmineWorkload::WlDateTools.working_days_in_time_span(start_date..end_date, @user, no_cache: true)
  end

  test 'working_days_in_time_span works if only weekends and mondays are holidays and startday is thursday, endday is tuesday.' do
    # Set saturday, sunday and monday to be a holiday, all others to be a working day.
    Setting['plugin_redmine_workload']['general_workday_monday'] = ''
    Setting['plugin_redmine_workload']['general_workday_tuesday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_wednesday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_thursday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_friday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_saturday'] = ''
    Setting['plugin_redmine_workload']['general_workday_sunday'] = ''

    start_date = Date.new(2005, 12, 29) # A thursday
    end_date = Date.new(2006, 1, 3) # A tuesday

    expected_result = [
      start_date,
      Date.new(2005, 12, 30),
      end_date
    ]

    assert_equal Set.new(expected_result), RedmineWorkload::WlDateTools.working_days_in_time_span(start_date..end_date, @user, no_cache: true)
  end

  test 'working_days returns the working days.' do
    # Set saturday, sunday and monday to be a holiday, all others to be a working day.
    Setting['plugin_redmine_workload']['general_workday_monday'] = ''
    Setting['plugin_redmine_workload']['general_workday_tuesday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_wednesday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_thursday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_friday'] = 'checked'
    Setting['plugin_redmine_workload']['general_workday_saturday'] = ''
    Setting['plugin_redmine_workload']['general_workday_sunday'] = ''

    assert_equal Set.new([2, 3, 4, 5]), RedmineWorkload::WlDateTools.working_days
  end

    test 'getMonthsBetween returns [] if last day after first day' do
      first_day = Date.new(2012, 3, 29)
      last_day = Date.new(2012, 3, 28)

    assert_equal [], RedmineWorkload::WlDateTools.months_in_time_span(first_day..last_day)
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

  test 'should recognize a users vacation day' do
    user1, user2 = users_defined
    user1.wl_user_vacations.create(date_from: first_day, date_to: first_day)
    user2.wl_user_vacations.create(date_from: last_day, date_to: last_day)
    assert RedmineWorkload::WlDateTools.vacation?(first_day, user1)
    assert_not RedmineWorkload::WlDateTools.vacation?(first_day, user2)
  end

    private

  def months_numbers_in_time_span(first_day, last_day)
    RedmineWorkload::WlDateTools.months_in_time_span(first_day..last_day).map do |span|
      [span[:first_day].month, span[:last_day].month]
    end
  end
end
