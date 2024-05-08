# frozen_string_literal: true

require_relative "./config/test_helper"

# bad_user:
#   - first_name
#   - last_name
#   - missing_field

MissingFieldUser = Struct.new(:first_name, :last_name)

class NoMethodErrorTest < Minitest::Spec
  include Donatello

  let(:mock_yaml_location) do
    File.join(__dir__, "config", "serialization_schema.yaml")
  end
  let(:user) do
    MissingFieldUser.new("Wont", "Deliver")
  end

  before do
    Donatello.reset!
    Donatello.setup do |c|
      c.schema_location = mock_yaml_location
    end
  end

  it "raises an error when an object can't respond to a message" do
    assert_raises StandardError do
      serialize(user, :bad_user)
    end
    begin
      serialize(user, :bad_user)
    rescue StandardError => e
      assert_hash_equal "Error: Cannot process item - object does not respond to 'missing_field'.", e.message
    end
  end
end
