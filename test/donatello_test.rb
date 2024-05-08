# frozen_string_literal: true

require_relative "./config/test_helper"

class DonatelloTest < Minitest::Spec
  let(:default_yaml_location) do
    File.join(Dir.pwd, "config", "serialization_schema.yaml")
  end

  let(:mock_yaml_location) do
    File.join(__dir__, "config", "serialization_schema.yaml")
  end

  before do
    Donatello.reset!
  end

  it "has a default schema location" do
    Donatello.setup

    assert_equal default_yaml_location, Donatello.schema_location
  end

  it "lets you configure the schema location" do
    Donatello.setup do |config|
      config.schema_location = "path/to/yaml"
    end

    assert_equal "path/to/yaml", Donatello.schema_location
  end

  it "ensures the yaml is loaded" do
    Donatello.setup do |config|
      config.schema_location = mock_yaml_location
    end

    assert_equal YAML.load_file(mock_yaml_location), Donatello.schema
  end
end
