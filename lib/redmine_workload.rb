# frozen_string_literal: true

require 'redmine_workload/extensions/user_patch'
require 'redmine_workload/date_tools'
require 'redmine_workload/group_workload_preparer'
require 'redmine_workload/user_workload_preparer'
require 'redmine_workload/wl_csv_exporter'
require 'redmine_workload/wl_issue_query'
require 'redmine_workload/wl_user_data_finder'
require 'redmine_workload/wl_user_data_defaults'

module RedmineWorkload
  def self.major_release_deprecator
    ActiveSupport::Deprecation.new('2.0.0', 'Redmine Workload')
  end
end
