# frozen_string_literal: true

module Donatello # rubocop:disable Style/Documentation
  def serialize(object, schema_name)
    applied = apply_schema(object, schema_name)
    # Don't include the root
    applied ? Oj.dump(applied[schema_name]) : Oj.dump(nil)
  end

  def apply_schema(object, schema_name) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    schema = Donatello.schema[schema_name.to_s]

    # ex. schema: `empty:`
    return nil if schema.nil?

    # Handle collections of objects
    if object.is_a?(Array)
      result = object.map do |o|
        apply_schema(o, schema_name)[schema_name]
      end
      return { schema_name => result }
    end

    schema.inject({}) do |acc, (_key, _value)| # rubocop:disable Metrics/BlockLength
      case schema

      # ex. `{ "creator" => ["id", "first_name", "last_name"] }`
      when Array
        results = schema.inject({}) do |obj, item| # rubocop:disable Metrics/BlockLength
          if item.is_a?(Hash)
            with_entry = item["with"]
            if with_entry.is_a?(String)
              obj.merge(
                apply_schema(object, with_entry)[with_entry]
              )
            elsif with_entry.is_a?(Array)
              obj.merge(
                with_entry.inject({}) do |with_combined, with_key|
                  with_combined.merge(
                    apply_schema(object, with_key)[with_key]
                  )
                end
              )
            else
              attr_config = item.values.first || {}
              serializer_entry = item["serializer"] ||
                                 attr_config["serializer"] ||
                                 attr_config[:serializer]
              alias_entry = item["alias"] ||
                            attr_config["alias"] ||
                            attr_config[:alias]
              attribute_name = item.keys.map(&:to_s).find { |k| !%w[alias serializer].include?(k) }
              schema_key = serializer_entry || attribute_name
              alias_key = alias_entry || attribute_name
              sub_object = object.send(attribute_name)
              obj.merge(
                { alias_key => apply_schema(sub_object, schema_key)[schema_key] }
              )
            end
          elsif object.respond_to?(item)
            result = object.send(item)
            case result
            when Date, DateTime, Time
              obj.merge({ item => result.iso8601 })
            else
              obj.merge({ item => result })
            end
          else
            raise StandardError, "Error: Cannot process item - object does not respond to '#{item}'."
          end
        end
        acc.merge({ schema_name => results })
      when nil
        acc.merge({ schema_name => nil })
      else
        acc
      end
    end
  end
end
