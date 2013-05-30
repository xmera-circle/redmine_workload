require File.expand_path('../../test_helper', __FILE__)

class DateToolsTest < ActiveSupport::TestCase

  test "getRealDistanceInDays returns 1 if start and end day are equal and no holiday." do
    
    # Set friday to be a working day.
    Setting.plugin_redmine_workload['general_workday_friday'] = 'checked';

    date = Date.new(2005, 12, 30);      # A friday
    assert_equal 1, DateTools::getRealDistanceInDays(date, date);
  end

  test "getRealDistanceInDays returns 0 if start and end day are equal and a holiday." do

    # Set friday to be a holiday.
    Setting.plugin_redmine_workload['general_workday_friday'] = '';

    date = Date.new(2005, 12, 30);      # A friday
    assert_equal 0, DateTools::getRealDistanceInDays(date, date);
  end

  test "getRealDistanceInDays returns 0 if start day before end day." do
    
    startDate = Date.new(2005, 12, 30); # A friday
    endDate = Date.new(2005, 12, 28);   # A wednesday
    assert_equal 0, DateTools::getRealDistanceInDays(startDate, endDate);
  end

  test "getRealDistanceInDays returns 0 if both days follow each other and are holidays." do

    # Set wednesday and thursday to be a holiday.
    Setting.plugin_redmine_workload['general_workday_wednesday'] = '';
    Setting.plugin_redmine_workload['general_workday_thursday'] = '';

    startDate = Date.new(2005, 12, 28); # A wednesday
    endDate = Date.new(2005, 12, 29);     # A thursday
    assert_equal 0, DateTools::getRealDistanceInDays(startDate, endDate);
  end

  test "getRealDistanceInDays returns 3 if only weekends and mondays are holidays and startday is thursday, endday is tuesday." do

    # Set saturday, sunday and monday to be a holiday, all others to be a working day.
    Setting.plugin_redmine_workload['general_workday_monday'] = '';
    Setting.plugin_redmine_workload['general_workday_tuesday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_wednesday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_thursday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_friday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_saturday'] = '';
    Setting.plugin_redmine_workload['general_workday_sunday'] = '';

    startDate = Date.new(2005, 12, 29); # A thursday
    endDate = Date.new(2006, 1, 3);     # A tuesday
    assert_equal 3, DateTools::getRealDistanceInDays(startDate, endDate);
  end

  test "getWorkingDays returns the working days." do

    # Set saturday, sunday and monday to be a holiday, all others to be a working day.
    Setting.plugin_redmine_workload['general_workday_monday'] = '';
    Setting.plugin_redmine_workload['general_workday_tuesday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_wednesday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_thursday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_friday'] = 'checked';
    Setting.plugin_redmine_workload['general_workday_saturday'] = '';
    Setting.plugin_redmine_workload['general_workday_sunday'] = '';

    assert_equal [ 2, 3, 4, 5], DateTools::getWorkingDays()
  end

end
