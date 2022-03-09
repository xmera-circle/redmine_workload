# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class RoutingWlUserDataTest < Redmine::RoutingTest
  def test_wl_user_data
    should_route 'GET  /wl_user_datas/1/edit' => 'wl_user_datas#edit', id: '1'
    should_route 'PATCH /wl_user_datas/1' => 'wl_user_datas#update', id: '1'
  end
end
