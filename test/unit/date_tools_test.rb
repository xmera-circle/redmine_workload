# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class DateToolsTest < ActiveSupport::TestCase
  test 'working_days_in_time_span works if start and end day are equal and no holiday.' do
    # Set friday to be a working day.
    Setting['plugin_redmine_workload']['general_workday_friday'] = 'checked'

    date = Date.new(2005, 12, 30); # A friday
    assert_equal Set.new([date]), DateTools.working_days_in_time_span(date..date, 'all', no_cache: true)
  end

  test 'working_days_in_time_span works if start and end day are equal and a holiday.' do
    # Set friday to be a holiday.
    Setting['plugin_redmine_workload']['general_workday_friday'] = ''

    date = Date.new(2005, 12, 30);      # A friday
    assert_equal Set.new, DateTools.working_days_in_time_span(date..date, 'all', no_cache: true)
  end

  test 'working_days_in_time_span works if start day before end day.' do
    startDate = Date.new(2005, 12, 30); # A friday
    endDate = Date.new(2005, 12, 28);   # A wednesday
    assert_equal Set.new, DateTools.working_days_in_time_span(startDate..endDate, 'all', no_cache: true)
  end

  test 'working_days_in_time_span works if both days follow each other and are holidays.' do
    # Set wednesday and thursday to be a holiday.
    Setting['plugin_redmine_workload']['general_workday_wednesday'] = ''
    Setting['plugin_redmine_workload']['general_workday_thursday'] = ''

    startDate = Date.new(2005, 12, 28); # A wednesday
    endDate = Date.new(2005, 12, 29); # A thursday
    assert_equal Set.new, DateTools.working_days_in_time_span(startDate..endDate, 'all', no_cache: true)
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

    startDate = Date.new(2005, 12, 29); # A thursday
    endDate = Date.new(2006, 1, 3);     # A tuesday

    expectedResult = [
      startDate,
      Date.new(2005, 12, 30),
      endDate
    ]

    assert_equal Set.new(expectedResult), DateTools.working_days_in_time_span(startDate..endDate, 'all', no_cache: true)
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

    assert_equal Set.new([2, 3, 4, 5]), DateTools.working_days
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

  private

  def months_numbers_in_time_span(first_day, last_day)
    DateTools.months_in_time_span(first_day..last_day).map do |span|
      [span[:first_day].month, span[:last_day].month]
    end
  end
end
