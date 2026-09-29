# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WlGroupSettingsControllerTest < ActionDispatch::IntegrationTest
    include RedmineWorkload::AuthenticateUser

    fixtures :users, :roles, :groups_users

    def setup
      @field = RedmineWorkload::WlGroupExclusion.ensure_custom_field!
      @group = Group.generate!
    end

    test 'should require an administrator' do
      log_user('jsmith', 'jsmith')

      get wl_group_settings_path
      assert_response :forbidden
    end

    test 'should list the groups' do
      log_user('admin', 'admin')

      get wl_group_settings_path
      assert_response :success
      assert_select "input#excluded_group_#{@group.id}[type=checkbox]"
    end

    test 'should mark and unmark a group' do
      log_user('admin', 'admin')

      put wl_group_settings_path, params: { excluded_group_ids: [@group.id] }
      assert_redirected_to wl_group_settings_path
      assert RedmineWorkload::WlGroupExclusion.excluded?(@group.reload)

      put wl_group_settings_path, params: {}
      assert_redirected_to wl_group_settings_path
      assert_not RedmineWorkload::WlGroupExclusion.excluded?(@group.reload)
    end

    test 'should offer to recreate a deleted custom field' do
      @field.destroy
      log_user('admin', 'admin')

      get wl_group_settings_path
      assert_response :success
      assert_select 'form[action=?]', wl_group_settings_custom_field_path

      post wl_group_settings_custom_field_path
      assert_redirected_to wl_group_settings_path
      assert RedmineWorkload::WlGroupExclusion.configured?
    end
  end
end
