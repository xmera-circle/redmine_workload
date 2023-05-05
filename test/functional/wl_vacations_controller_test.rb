# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WlUserVacationsControllerTest < ActionDispatch::IntegrationTest
    include RedmineWorkload::AuthenticateUser

    fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
             :users, :issue_statuses, :enumerations, :roles

    test 'should get index' do
      log_user('jsmith', 'jsmith')

      get wl_user_vacations_path
      assert_response :success
    end

    test 'should not create new vacation when user is not allowed to' do
      log_user('jsmith', 'jsmith')

      post wl_user_vacations_path,
           params: { wl_user_vacations:
                    { date_from: today, date_to: tomorrow, comment: 'Eastern' } }
      assert_response :forbidden
    end

    test 'should create new vacation' do
      manager = roles :roles_001
      manager.add_permission! :edit_user_vacations
      log_user('jsmith', 'jsmith')

      post wl_user_vacations_path,
           params: { wl_user_vacations:
                    { date_from: today, date_to: tomorrow, comment: 'Eastern' } }
      assert_redirected_to wl_user_vacations_path
    end

    test 'should not update vacation when user is not allowed to' do
      vacation = generate_vacation
      log_user('jsmith', 'jsmith')

      patch wl_user_vacation_path(id: vacation.id),
            params: { wl_user_vacation: { comment: 'No comment' } }
      assert_response :forbidden
    end

    test 'should update vacation' do
      vacation = generate_vacation
      manager = roles :roles_001
      manager.add_permission! :edit_user_vacations
      log_user('jsmith', 'jsmith')

      patch wl_user_vacation_path(id: vacation.id),
            params: { wl_user_vacation: { comment: 'No comment' } }
      assert_redirected_to wl_user_vacations_path
    end

    test 'should not destroy vacation when user is not allowed to' do
      vacation = generate_vacation
      log_user('jsmith', 'jsmith')

      delete wl_user_vacation_path(id: vacation.id)
      assert_response :forbidden
    end

    test 'should destroy vacation' do
      vacation = generate_vacation
      manager = roles :roles_001
      manager.add_permission! :edit_user_vacations
      log_user('jsmith', 'jsmith')

      delete wl_user_vacation_path(id: vacation.id)
      assert_redirected_to wl_user_vacations_path
    end

    private

    def generate_vacation
      WlUserVacation.create(user_id: 2, date_from: today, date_to: tomorrow, comments: 'Private')
    end

    def today
      Time.zone.today
    end

    def tomorrow
      today + 1
    end
  end
end
