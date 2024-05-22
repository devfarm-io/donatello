# frozen_string_literal: true

module Donatello # rubocop:disable Style/Documentation
  MAX_LEVELS = 4 # TODO: make this configurable

  def serialize(object, schema_name)
    applied = apply_schema(object, schema_name, 0)
    # Don't include the root
    applied ? Oj.dump(applied[schema_name]) : Oj.dump(nil)
  end

  def apply_schema(object, schema_name, current_level = 0) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    # Stack level is too deep, return
    return { schema_name => nil } if current_level > MAX_LEVELS || object.nil?

    schema = Donatello.schema[schema_name.to_s]

    # Handle empty schemas
    # ex. schema: `empty:`
    return nil if schema.nil?

    # Handle collections of objects
    if non_hash_enumerable?(object)
      result = object.map do |o|
        apply_schema(o, schema_name, current_level + 1)[schema_name]
      end
      return { schema_name => result }
    end

    # We can process this schema
    result = schema.inject({}) do |acc, item|
      # TODO: detect cycles
      # TODO: add a test for cycles
      # TODO: add a pretty print to show the stack when stack level too deep
      # TODO: add a pretty print to show the stack when there's a cycle
      if item.is_a?(Hash)
        if item["with"]
          acc.merge(
            handle_with(object, item, current_level) || {}
          )
        else
          acc.merge(
            handle_attribute_config(object, item, current_level) || {}
          )
        end
      elsif object.respond_to?(item)
        acc.merge(
          handle_attribute(object, item) || {}
        )
      else
        handle_exception(object, item)
      end
    end

    { schema_name => result }
  end

  private

  def handle_exception(object, item)
    raise StandardError,
          "Error: Cannot process item - object (#{object.class}) (#{object.inspect}) does not respond to '#{item}'."
  end

  def handle_attribute(object, item)
    result = object.send(item)
    case result
    when Date, DateTime, Time
      { item => result.iso8601 }
    else
      { item => result }
    end
  end

  def entry_for(key, item)
    attr_config = item.values.first || {}
    item[key.to_sym] || item[key.to_s] || attr_config[key.to_sym] || attr_config[key.to_s]
  end

  def handle_attribute_config(object, item, current_level)
    serializer_entry = entry_for(:serializer, item)
    alias_entry = entry_for(:alias, item)
    attribute_name = item.keys.map(&:to_s).find { |k| !%w[alias serializer].include?(k) }
    schema_key = serializer_entry || attribute_name
    alias_key = alias_entry || attribute_name
    sub_object = object.send(attribute_name)

    { alias_key => apply_schema(sub_object, schema_key, current_level + 1)[schema_key] }
  end

  def handle_with(object, item, current_level)
    with_entry = item["with"]
    if with_entry.is_a?(String)
      apply_schema(object, with_entry, current_level + 1)[with_entry]
    elsif with_entry.is_a?(Array)
      handle_multiple_with(object, with_entry, current_level)
    else
      {}
    end
  end

  def handle_multiple_with(object, with_entry, current_level)
    with_entry.inject({}) do |with_combined, with_key|
      res = apply_schema(object, with_key, current_level + 1)[with_key]
      with_combined.merge(res || {})
    end
  end

  def non_hash_enumerable?(object)
    object.respond_to?(:each) && !object.is_a?(Hash)
  end
end
