# frozen_string_literal: true

require "forwardable"
require "oj"

require "donatello/version"
require "donatello/serializer" # assuming this is your main module
require "donatello/railtie" if defined?(Rails)

module Donatello # rubocop:disable Style/Documentation
  if defined?(Rails)
    Oj.optimize_rails # Optimizes Oj for compatibility with Rails

  else
    Oj.default_options = {
      use_to_json: true,
      use_as_json: true,
      time_format: :xmlschema,
      second_precision: 3
    }
    Oj.add_to_json
  end
  class << self
    extend Forwardable

    def setup
      yield config if block_given?
    end

    def reset!
      @config = nil
    end

    def config
      @config ||= Config.new
    end

    def_delegator :config, :schema_location
    def_delegator :config, :schema
  end

  class Config # rubocop:disable Style/Documentation
    def initialize
      @schema_location = if defined?(Rails)
                           Rails.root.join(
                             "config", "serialization_schema.yml"
                           )
                         else
                           File.join(Dir.pwd, "config", "serialization_schema.yaml")
                         end
    end

    attr_accessor :schema_location

    def schema
      @schema ||= YAML.load_file(schema_location)
    end
  end
end
