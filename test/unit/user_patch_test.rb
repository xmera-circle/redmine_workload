# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class UserPatchTest < ActiveSupport::TestCase
  test 'should respond to wl_user_data' do
    user = User.generate!
    assert user.respond_to? :wl_user_data
  end

  test 'should repsond to wl_user_vacations' do
    user = User.generate!
    assert user.respond_to? :wl_user_vacations
  end
end
