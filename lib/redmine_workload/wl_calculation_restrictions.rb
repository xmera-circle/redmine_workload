# frozen_string_literal: true

module RedmineWorkload

module WlCalculationRestrictions
  def consider_parent_issues?
    settings['workload_of_parent_issues'].present?
  end

    def settings
      Setting.plugin_redmine_workload
    end
  end
end

end