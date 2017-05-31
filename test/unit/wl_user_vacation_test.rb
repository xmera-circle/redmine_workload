require File.expand_path('../../test_helper', __FILE__)

class WlUserVacationTest < ActiveSupport::TestCase
  fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
           :users, :issue_statuses, :enumerations, :roles
           
  setup do    
    # reset default settings
    Setting['plugin_redmine_workload']['general_workday_monday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_tuesday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_wednesday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_thursday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_friday'] = 'checked';
    Setting['plugin_redmine_workload']['general_workday_saturday'] = '';
    Setting['plugin_redmine_workload']['general_workday_sunday'] = '';
  end

  test "Vacation for user" do
    user1 = User.first
    vac1 = WlUserVacation.new(
      :date_from => Date::new(2017, 5, 30),
      :date_to => Date::new(2017, 5, 30),
      :vacation_type => "EU",
      :user_id => user1.id)
    
    assert vac1.save, "User Vacation could not be created!"    
    assert vac1.destroy, "User Vacation could deleted!"
  end
  
  test "vacation should be day off" do
    user1 = User.first
    day = Date::new(2017, 5, 30)
    vac1 = WlUserVacation.new(
      :date_from => day,
      :date_to => day,
      :vacation_type => "EU",
      :user_id => user1.id)
    
    vac1.save  
    
    assert DateTools::IsVacation(day, user1), "User should have Vacation!"
  end
  
  
  test "vacation should not be in working days" do

    user1 = User.first
    vac1 = WlUserVacation.new(
      :date_from => Date::new(2017, 5, 30),
      :date_to => Date::new(2017, 5, 31),
      :vacation_type => "EU",
      :user_id => user1.id)
    
    vac1.save  
    
    firstDay = Date::new(2017, 5, 29) 
    lastDay = Date::new(2017, 6, 1)   
            
    result = DateTools::getWorkingDaysInTimespan(firstDay..lastDay, user1)

    assert_equal [firstDay, lastDay], result.to_a, "Result should only bring 2 workdays!"
  end  
  
end