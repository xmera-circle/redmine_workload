# frozen_string_literal: true

module RedmineWorkload
  ##
  # Lets administrators keep groups out of the workload group filter.
  #
  # The decision lives on the group itself, as a boolean GroupCustomField that
  # this module creates on install. It can be edited in two places -- on the
  # group form, where Redmine renders custom fields anyway, and collected on
  # the plugin's group settings page -- but there is only one value.
  #
  # The field is looked up by id, stored in the plugin settings, so renaming it
  # does no harm. If it has been deleted the module fails open: nothing is
  # excluded until the field is created again.
  #
  module WlGroupExclusion
    SETTING_KEY = 'exclude_group_custom_field_id'
    FIELD_NAME = 'Exclude from workload planning'

    module_function

    ##
    # @return [GroupCustomField, nil] The field, or nil if not configured or deleted.
    #
    def custom_field
      id = settings[SETTING_KEY]
      return nil if id.blank?

      GroupCustomField.find_by(id: id)
    end

    def configured?
      custom_field.present?
    end

    ##
    # @return [Array(Integer)] Ids of the groups marked as excluded.
    #
    def excluded_group_ids
      field = custom_field
      return [] unless field

      CustomValue.where(custom_field_id: field.id, value: '1').pluck(:customized_id)
    end

    ##
    # @param group [Group]
    # @return [Boolean]
    #
    def excluded?(group)
      field = custom_field
      return false unless field

      group.custom_field_value(field).to_s == '1'
    end

    ##
    # Removes the excluded groups from the given collection.
    #
    # @param groups [Array(Group)]
    # @return [Array(Group)]
    #
    def reject_excluded(groups)
      excluded = excluded_group_ids
      return groups if excluded.empty?

      groups.reject { |group| excluded.include?(group.id) }
    end

    ##
    # Creates the custom field unless it already exists and remembers its id.
    # Used by the migration and by the settings page to recreate a deleted field.
    #
    # @return [GroupCustomField]
    #
    def ensure_custom_field!
      existing = custom_field
      return existing if existing

      field = GroupCustomField.create!(name: FIELD_NAME,
                                       field_format: 'bool',
                                       edit_tag_style: 'check_box',
                                       default_value: '0',
                                       is_required: false,
                                       visible: true,
                                       editable: true)
      store_id(field.id)
      field
    end

    ##
    # Destroys the field and its values, and forgets the id. Used by the
    # migration rollback.
    #
    def remove_custom_field!
      custom_field&.destroy
      store_id(nil)
    end

    def store_id(id)
      current = settings.to_h.dup
      current[SETTING_KEY] = id
      Setting.plugin_redmine_workload = current
    end

    def settings
      Setting.plugin_redmine_workload || {}
    end
  end
end
