# frozen_string_literal: true

require_relative "./config/test_helper"

# empty:

DoesntMatter = Struct.new(:id)

class EmptySerializersTest < Minitest::Spec
  include Donatello

  let(:mock_yaml_location) do
    File.join(__dir__, "config", "serialization_schema.yaml")
  end
  let(:object) do
    DoesntMatter.new(123)
  end

  before do
    Donatello.reset!
    Donatello.setup do |c|
      c.schema_location = mock_yaml_location
    end
  end

  it "does nothing if the schema is empty" do
    assert_hash_equal Oj.dump(nil), serialize(object, :empty)
  end
end
