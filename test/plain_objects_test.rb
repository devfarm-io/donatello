# frozen_string_literal: true

require "oj"

require_relative "./config/test_helper"

# common_fields:
#   - id
#   - created_at
#   - updated_at

Common = Struct.new(:id, :created_at, :updated_at, :extraneous_field)

class PlainObjectsTest < Minitest::Spec
  include Donatello

  let(:mock_yaml_location) do
    File.join(__dir__, "config", "serialization_schema.yaml")
  end
  let(:common_object) do
    Common.new(
      123,
      Date.new(2030, 2, 3).to_s,
      DateTime.new(2045, 5, 14).to_s,
      "extraneous_field_info"
    )
  end

  before do
    Donatello.reset!
    Donatello.setup do |c|
      c.schema_location = mock_yaml_location
    end
  end

  it "serializes a basic, flat object" do
    assert_hash_equal Oj.dump({
                                "id" => 123,
                                "created_at" => "2030-02-03",
                                "updated_at" => "2045-05-14T00:00:00+00:00"
                              }), serialize(common_object, :common_fields)
  end

  it "serializes an array of flat objects" do
    assert_hash_equal Oj.dump([{
                                "id" => 123,
                                "created_at" => "2030-02-03",
                                "updated_at" => "2045-05-14T00:00:00+00:00"
                              }, {
                                "id" => 123,
                                "created_at" => "2030-02-03",
                                "updated_at" => "2045-05-14T00:00:00+00:00"
                              }]), serialize([common_object, common_object], :common_fields)
  end
end
