# frozen_string_literal: true

require 'forwardable'

##
# Presenter organising users to be used in views/workloads/_filers.erb.
#
class UserSelection
  extend Forwardable

  def_delegators 'ListUser', :users_allowed_to_display, :users_of_groups

  def initialize(**params)
    self.users = params[:users] || []
    self.selected_groups = params[:selected_groups]
    self.helper_klass = 'ListUser'
  end

  ##
  # Prepares users to be used in filters
  def to_display
    (users_by_group | users_by_params) & allowed_to_display
  end

  ##
  # Prepares users to be used in filters
  def allowed_to_display
    users_allowed_to_display.sort_by { |user| user[:lastname] }
  end

  private

  attr_accessor :users, :selected_groups, :helper_klass

  ##
  # @return [ActiveRecord::Relation] Result of a user table query.
  def users_by_params
    User.where(id: user_ids)
  end

  def users_by_group
    users_of_groups(selected_groups)
  end

  def user_ids
    users.map(&:to_i)
  end
end
