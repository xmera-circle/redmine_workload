# frozen_string_literal: true

##
# Presenter organising groups to be used in views/workloads/_filers.erb.
#
class GroupSelection
  def initialize(**params)
    self.groups = params[:groups] || []
  end

  ##
  # Prepares groups to be used in filters
  def to_display
    Group.all.sort_by { |group| group[:lastname] }
  end

  ##
  # Prepares users to be used in filters
  def selected
    groups_by_params & to_display
  end

  private

  attr_accessor :groups

  def groups_by_params
    Group.where(id: group_ids)
  end

  def group_ids
    groups.map(&:to_i)
  end
end
