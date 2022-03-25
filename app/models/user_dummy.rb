# frozen_string_literal: true

require 'forwardable'

##
# Dummy representing a user of a group who holds all issues haven't been assigned
# to a real group member yet.
#
class UserDummy
  include Redmine::I18n
  extend Forwardable

  def_delegators :group, :firstname, :id 

  attr_reader :group

  ##
  # @params group [Group] An instance of Group model. 
  #
  def initialize(group:)
    self.group = group
  end

  def lastname
    l(:label_assigned_to_group, value: group.lastname)
  end

  private

  attr_writer :group
end
