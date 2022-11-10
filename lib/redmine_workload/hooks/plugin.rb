# frozen_string_literal: true

module RedmineWorkload
  module Hooks
    class AfterPluginsLoadedHook < Redmine::Hook::Listener
      def after_plugins_loaded(context = {})
        if Rails.version > '6'
          unless User.included_modules.include?(RedmineWorkload::Extensions::UserPatch)
            User.prepend RedmineWorkload::Extensions::UserPatch
          end
        end
      end
    end
  end
end
