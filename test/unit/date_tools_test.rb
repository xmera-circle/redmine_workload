require File.expand_path('../../test_helper', __FILE__)

class DateToolsTest < ActiveSupport::TestCase

  test "getRealDistanceInDays returns 1 if start and end day are equal." do

    date = Date.new(2005, 12, 28);

    assert_equal 1, DateTools.getRealDistanceInDays(date, date);
  end

end
