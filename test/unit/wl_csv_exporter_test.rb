# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class WlCsvExporterTest < ActiveSupport::TestCase

  def setup 
    @exporter = WlCsvExporter.new(data: nil, params: {})
  end

  test 'should respond to data' do
    assert @exporter.respond_to? :data
  end

  test 'should respond to header_fields' do
    assert @exporter.respond_to? :header_fields
  end

  test 'should respond to line' do
    assert @exporter.respond_to? :line
  end

  test 'should initialize UserWorkloadPreparer object' do
    data = UserWorkload.new(assignees: [], time_span: 1..5, today: Time.zone.today)
    assert_equal 'UserWorkloadPreparer', @exporter.send(:initialize_data_object, data).class.name
  end

  test 'should initialize GroupWorkloadPreparer object' do
    data = GroupWorkload.new(users: UserSelection.new, user_workload: {}, time_span: 1..5)
    assert_equal 'GroupWorkloadPreparer', @exporter.send(:initialize_data_object, data).class.name
  end
end
