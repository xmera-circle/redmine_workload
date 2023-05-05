# frozen_string_literal: true

# Load the normal Rails helper
require Rails.root.join('test/test_helper.rb')
# Load other test helper modules
require File.expand_path('authenticate_user', __dir__)
require File.expand_path('workload_object_helper', __dir__)
