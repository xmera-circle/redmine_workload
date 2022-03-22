# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class WlUserDatasControllerTest < ActionDispatch::IntegrationTest
  include RedmineWorkload::AuthenticateUser
  include WlUserDataFinder

  fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
           :users, :issue_statuses, :enumerations, :roles

  def setup
    find_user_workload_data
    @group = Group.generate!
  end

  test 'should render edit' do
    log_user('jsmith', 'jsmith')

    get edit_wl_user_data_path(@user_workload_data)
    assert_response :success
    assert_match(/jsmith/, response.body)
  end

  test 'should update data if user allowed to' do
    jsmith = users :users_002
    manager = roles :roles_001
    manager.add_permission! :edit_user_data
    jsmith.groups << @group
    log_user('jsmith', 'jsmith')

    patch wl_user_data_path(@user_workload_data),
          params: { wl_user_data: to_be_updated(@group.id) }

    assert_redirected_to controller: :workloads, action: :index
    wl_user_data = WlUserData.find_by(user_id: jsmith.id)
    current = wl_user_data.attributes
    expected = { 'id' => wl_user_data.id,
                 'user_id' => jsmith.id,
                 'threshold_lowload_min' => 2.0,
                 'threshold_normalload_min' => 4.0,
                 'threshold_highload_min' => 6.0,
                 'main_group' => @group.id }
    assert_equal expected, current
  end

  test 'should not update data if user not allowed to' do
    jsmith = users :users_002
    jsmith.groups << @group
    log_user('jsmith', 'jsmith')

    patch wl_user_data_path(@user_workload_data),
          params: { wl_user_data: to_be_updated(@group.id) }

    assert :forbidden
  end

  test 'should render errors messages' do
    jsmith = users :users_002
    manager = roles :roles_001
    manager.add_permission! :edit_user_data
    jsmith.groups << @group
    log_user('jsmith', 'jsmith')

    patch wl_user_data_path(@user_workload_data),
          params: { wl_user_data: to_be_updated(1) }

    assert :success
    # Use this assertion when error rendering is refactored!
    # assert_select_error /is not included in the list/
    assert_select 'div.flash.error', text: /is not included in the list/
  end

  private

  def to_be_updated(group_id)
    { threshold_lowload_min: 2,
      threshold_normalload_min: 4,
      threshold_highload_min: 6,
      main_group: group_id }
  end
end
