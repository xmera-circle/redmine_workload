# frozen_string_literal: true

##
# Creates the boolean group custom field that marks groups as excluded from
# the workload group filter, and stores its id in the plugin settings.
#
# This writes data, not schema. Rolling back destroys the field together with
# its values -- acceptable for an uninstall, which is the only reason to roll
# this back.
#
class CreateWlGroupExclusionCustomField < ActiveRecord::Migration[7.2]
  def up
    RedmineWorkload::WlGroupExclusion.ensure_custom_field!
  end

  def down
    RedmineWorkload::WlGroupExclusion.remove_custom_field!
  end
end
