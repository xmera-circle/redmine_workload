# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WlGroupSettingsControllerTest < ActionDispatch::IntegrationTest
    include RedmineWorkload::AuthenticateUser
    include WlUserDataDefaults

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

    test 'should list the groups with their user and main group counts' do
      member = User.generate!
      member.groups << @group
      member.create_wl_user_data(default_attributes.merge(main_group: @group.id))
      log_user('admin', 'admin')

      get wl_group_settings_path
      assert_response :success
      assert_select "input#excluded_group_#{@group.id}[type=checkbox]"
      assert_select 'tr', text: /#{Regexp.escape(@group.name)}/ do
        assert_select 'td.user_count', text: '1'
        assert_select 'td.main_group_count', text: /1/
      end
    end

    test 'should warn where an excluded group is still a main group' do
      member = User.generate!
      member.groups << @group
      member.create_wl_user_data(default_attributes.merge(main_group: @group.id))
      group = Group.find(@group.id)
      group.custom_field_values = { @field.id.to_s => '1' }
      group.save!
      log_user('admin', 'admin')

      get wl_group_settings_path
      assert_response :success
      assert_select 'td.main_group_count span.icon-warning', count: 1
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
