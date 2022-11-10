# frozen_string_literal: true

module RedmineWorkload
  module Hooks
    class AfterPluginsLoadedHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        return unless Rails.version > '6'

        patch = RedmineWorkload::Extensions::UserPatch
        klass = User
        klass.prepend patch unless klass.included_modules.include?(patch)
      end
    end
  end
end
