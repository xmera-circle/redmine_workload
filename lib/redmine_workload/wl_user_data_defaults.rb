# frozen_string_literal: true

module RedmineWorkload
  ##
  # Provides the default values for WlUserData object
  #
  module WlUserDataDefaults
    def default_attributes
      { threshold_lowload_min: settings['threshold_lowload_min'],
        threshold_normalload_min: settings['threshold_normalload_min'],
        threshold_highload_min: settings['threshold_highload_min'] }
    end

    def settings
      Setting['plugin_redmine_workload']
    end
  end
end
