# frozen_string_literal: true

require 'redmine_workload/date_tools'
require 'redmine_workload/list_user'
require 'redmine_workload/wl_user_data_finder'

module RedmineWorkload
  def self.major_release_deprecator
    ActiveSupport::Deprecation.new('2.0.0', 'Redmine Workload')
  end
end
