# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

module RedmineWorkload
  class RoutingWlGroupSettingsTest < Redmine::RoutingTest
    def test_wl_group_settings
      should_route 'GET  /wl_group_settings' => 'wl_group_settings#index'
      should_route 'PUT  /wl_group_settings' => 'wl_group_settings#update'
      should_route 'POST /wl_group_settings/custom_field' => 'wl_group_settings#create_custom_field'
    end
  end
end
