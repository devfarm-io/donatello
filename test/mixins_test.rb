# frozen_string_literal: true

require_relative "./config/test_helper"

EngagementUser = Struct.new(:id, :created_at, :updated_at,  # with: common
                            :first_name, :last_name,        # public_user
                            :likes_count, :comments_count,  # engagement
                            :favorite_color,                # engagement_user
                            :nickname)                      # ignored - not in the schema

# common_fields:
#   - id
#   - created_at
#   - updated_at
#
# engagement:
#   - likes_count
#   - comments_count
#
# public_user:
#   - with: common_fields # use a single mixin
#   - first_name
#   - last_name
#
# engagement_user:
#   - with:
#     - public_user
#     - engagement
#   - favorite_color

class MixinsTest < Minitest::Spec
  include Donatello

  let(:mock_yaml_location) do
    File.join(__dir__, "config", "serialization_schema.yaml")
  end
  let(:common_object) do
    EngagementUser.new(
      123,                    # id
      Date.new(2030, 2, 3),   # created_at
      Date.new(2045, 5, 14),  # updated_at
      "Jimmy",                # first_name
      "Neutron",              # last_name
      888,                    # likes_count
      777,                    # comments_count
      "red",                  # favorite_color
      "Bucky"                 # nickname - ignored
    )
  end

  before do
    Donatello.reset!
    Donatello.setup do |c|
      c.schema_location = mock_yaml_location
    end
  end

  it "includes attributes from a single mixin" do
    #   - with: public_user
    assert_hash_equal ({
      "id" => 123,
      "created_at" => Date.new(2030, 2, 3).to_s,
      "updated_at" => Date.new(2045, 5, 14).to_s,
      "first_name" => "Jimmy",
      "last_name" => "Neutron"
    }), Oj.load(serialize(common_object, :public_user))
  end

  it "includes attributes from multiple mixins" do
    #   - with:
    #     - public_user
    #     - engagement
    assert_hash_equal ({
      "id" => 123,
      "created_at" => Date.new(2030, 2, 3).to_s,
      "updated_at" => Date.new(2045, 5, 14).to_s,
      "first_name" => "Jimmy",
      "last_name" => "Neutron",
      "likes_count" => 888,
      "comments_count" => 777,
      "favorite_color" => "red"
    }), Oj.load(serialize(common_object, :engagement_user))
  end
end
