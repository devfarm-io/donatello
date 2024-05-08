# frozen_string_literal: true

require_relative "./config/test_helper"

# post_for_list:
#   - with: common_fields
#   - title
#
# topic:
#   - with: common_fields
#   - name
#   - posts:
#     serializer: post_for_list

PostForList = Struct.new(:id, :created_at, :updated_at, :title)
Topic = Struct.new(:id, :created_at, :updated_at, :name, :posts)

class ExplicitSerializersTest < Minitest::Spec
  include Donatello

  let(:mock_yaml_location) do
    File.join(__dir__, "config", "serialization_schema.yaml")
  end
  let(:date_1) do # rubocop:disable Naming/VariableNumber
    Date.new(2031, 1, 11)
  end
  let(:date_2) do # rubocop:disable Naming/VariableNumber
    Date.new(2032, 2, 22)
  end
  let(:date_3) do # rubocop:disable Naming/VariableNumber
    Date.new(2033, 3, 3)
  end
  let(:date_4) do # rubocop:disable Naming/VariableNumber
    Date.new(2034, 4, 4)
  end

  let(:posts) do
    [
      PostForList.new(
        111,
        date_1.to_s,
        date_2.to_s,
        "Why I use a bo staff"
      ),
      PostForList.new(
        222,
        date_3.to_s,
        date_4.to_s,
        "Mikey needs to chill with the surfer talk"
      )
    ]
  end
  let(:topic) do
    Topic.new(
      4444,
      date_3.to_s,
      date_2.to_s,
      "Donnie's Thoughts",
      posts
    )
  end
  let(:expected_payload) do
    {
      "id" => 4444,
      "created_at" => date_3.to_s,
      "updated_at" => date_2.to_s,
      "name" => "Donnie's Thoughts",
      "list_of_posts" => posts.map do |post|
                           {
                             "id" => post.id,
                             "title" => post.title,
                             "created_at" => post.created_at,
                             "updated_at" => post.updated_at
                           }
                         end
    }
  end

  before do
    Donatello.reset!
    Donatello.setup do |c|
      c.schema_location = mock_yaml_location
    end
  end

  # topic_idea_format:
  #   - with: common_fields
  #   - name
  #   - posts: # IDEAL
  #       serializer: post_for_list
  #       alias: list_of_posts
  it "uses the specified serializer when indicated - IDEAL" do
    assert_hash_equal expected_payload, Oj.load(serialize(topic, :topic_ideal_format))
  end

  # topic_not_great_format:
  #   - with: common_fields
  #   - name
  #   - posts: # NOT GREAT
  #     serializer: post_for_list
  #     alias: list_of_posts
  it "uses the specified serializer when indicated - NOT GREAT" do
    assert_hash_equal expected_payload, Oj.load(serialize(topic, :topic_not_great_format))
  end
end
