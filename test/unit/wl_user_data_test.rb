# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

module RedmineWorkload
  class WlUserDataTest < ActiveSupport::TestCase
    fixtures :trackers, :projects, :projects_trackers, :members, :member_roles,
             :users, :issue_statuses, :enumerations, :roles

    def setup
      @user = User.generate!
      @group = Group.generate!
    end

    def teardown
      User.current = nil
    end

    test 'should not validate workload user data without settings' do
      wl_user_data = WlUserData.new(user_id: @user.id)
      assert_not wl_user_data.valid?
      expected = %i[threshold_lowload_min threshold_highload_min threshold_normalload_min].sort
      current = wl_user_data.errors.messages.keys.sort
      assert_equal expected, current
    end

    test 'should validate workload user data with settings' do
      User.current = @user
      @user.groups << @group
      wl_user_data = WlUserData.new(user_id: @user.id,
                                    threshold_highload_min: 6,
                                    threshold_lowload_min: 3,
                                    threshold_normalload_min: 4,
                                    main_group: @group.id)
      assert wl_user_data.valid?, wl_user_data.errors.full_messages
    end

    test 'should not validate foreign main group' do
      foreign_group = Group.generate!
      @user.groups << @group
      wl_user_data = WlUserData.new(user_id: @user.id,
                                    threshold_highload_min: 6,
                                    threshold_lowload_min: 3,
                                    threshold_normalload_min: 4,
                                    main_group: foreign_group.id)
      assert_not wl_user_data.valid?
      expected = %i[main_group].sort
      current = wl_user_data.errors.messages.keys.sort
      assert_equal expected, current
    end
  end
end
