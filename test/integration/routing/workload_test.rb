# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

module RedmineWorkload
  class RoutingWorkloadTest < Redmine::RoutingTest
    def test_workloads
      should_route 'GET  /workloads' => 'workloads#index'
    end
  end
end
