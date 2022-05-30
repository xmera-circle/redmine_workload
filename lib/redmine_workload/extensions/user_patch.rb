# frozen_string_literal: true

module RedmineWorkload
  module Extensions
    module UserPatch
      def self.prepended(base)
        base.prepend(InstanceMethods)
        base.class_eval do
          has_one :wl_user_data, inverse_of: :user
          has_many :wl_user_vacations, inverse_of: :user
          delegate :main_group, to: :wl_user_data, allow_nil: true
        end
      end

      module InstanceMethods
        ##
        # Prefer to use main_group_id over User#wl_user_data.main_group since
        # the latter may lead to
        # NoMethodError Exception: undefined method `main_group' for nil:NilClass
        # when no data set for wl_user_data exists. In contrast, the delegation
        # of main_group, as used below, will handle this case.
        #
        def main_group_id
          main_group
        end
      end
    end
  end
end

# Apply patch
Rails.configuration.to_prepare do
  unless User.included_modules.include?(RedmineWorkload::Extensions::UserPatch)
    User.prepend RedmineWorkload::Extensions::UserPatch
  end
end
