# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class WlNationalHolidayControllerTest < ActionDispatch::IntegrationTest
  include RedmineWorkload::AuthenticateUser

  fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
           :users, :issue_statuses, :enumerations, :roles

  test 'should get index' do
    log_user('jsmith', 'jsmith')

    get wl_national_holiday_index_path
    assert_response :success
  end

  test 'should not create new holiday when user is not allowed to' do
    log_user('jsmith', 'jsmith')

    post wl_national_holiday_index_path
    assert_response :forbidden
  end

  test 'should create new national holiday' do
    manager = roles :roles_001
    manager.add_permission! :edit_national_holiday
    log_user('jsmith', 'jsmith')

    post wl_national_holiday_index_path,
         params: { wl_national_holiday:
                    { start: today, end: tomorrow, reason: 'Eastern' } }
    assert_redirected_to wl_national_holiday_index_path
  end

  test 'should not update holiday when user is not allowed to' do
    holiday = generate_holiday
    log_user('jsmith', 'jsmith')

    patch wl_national_holiday_path(id: holiday.id),
          params: { wl_national_holiday: { reason: 'New Year' } }
    assert_response :forbidden
  end

  test 'should update holiday' do
    holiday = generate_holiday
    manager = roles :roles_001
    manager.add_permission! :edit_national_holiday
    log_user('jsmith', 'jsmith')

    patch wl_national_holiday_path(id: holiday.id),
          params: { wl_national_holiday: { reason: 'New Year' } }
    assert_redirected_to wl_national_holiday_index_path
  end

  test 'should not destroy holiday when user is not allowed to' do
    holiday = generate_holiday
    log_user('jsmith', 'jsmith')

    delete wl_national_holiday_path(id: holiday.id)
    assert_response :forbidden
  end

  test 'should destroy holiday' do
    holiday = generate_holiday
    manager = roles :roles_001
    manager.add_permission! :edit_national_holiday
    log_user('jsmith', 'jsmith')

    delete wl_national_holiday_path(id: holiday.id)
    assert_redirected_to wl_national_holiday_index_path
  end

  private

  def generate_holiday
    WlNationalHoliday.create(start: today, end: tomorrow, reason: 'Christmas')
  end

  def today
    Time.zone.today
  end

  def tomorrow
    today + 1
  end
end
