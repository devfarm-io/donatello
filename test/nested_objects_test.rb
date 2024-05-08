# frozen_string_literal: true

require_relative "./config/test_helper"

Post = Struct.new(
  :id, :created_at, :updated_at, # common fields
  :likes_count, :comments_count, # engagement fields
  :title, :body,                 # simple attributes
  :author, :comments,            # associations w/ serializers
  :widgets                       # associations w/o serializers
)

Comment = Struct.new(
  :id, :created_at, :updated_at, # common fields
  :creator,                      # association w/ serializer
  :content                       # simple attributes
)

Author = Struct.new(
  :id, :created_at, :updated_at, # common fields
  :first_name, :middle_initial,  # simple attributes
  :last_name, :joined_at,
  :total_posts_count
)

Creator = Struct.new(
  :first_name, :last_initial     # simple attributes
)

Widget = Struct.new(
  :name,
  :quest,
  :favorite_color
)

class NestedObjectsTest < Minitest::Spec # rubocop:disable Metrics/ClassLength
  include Donatello

  let(:mock_yaml_location) do
    File.join(__dir__, "config", "serialization_schema.yaml")
  end

  # Schema:
  #
  # ```yaml
  #    common_fields:
  #      - id
  #      - created_at
  #      - updated_at
  #
  #    comment:
  #      - with: common_fields
  #      - content
  #      - creator:
  #          # The root of this node will be "commenter" but the `creator` message will be sent to the `comment` object
  #          alias: commenter
  #          # only include the first name, and last initial
  #          serializer: hidden_identity
  # ```
  #
  # Struct:
  #
  # ```ruby
  #    Comment = Struct.new(
  #      :id, :created_at, :updated_at, # common fields
  #      :creator,                      # association w/ serializer
  #      :content                       # simple attributes
  #    )
  # ```
  #
  let(:comments) do
    [
      Comment.new(5555,
                  Date.new(2024, 3, 20),
                  Date.new(2025, 5, 3),
                  commenter,
                  "This is a great article... not!!!@1~"),
      Comment.new(5556,
                  Date.new(2024, 3, 20),
                  Date.new(2025, 5, 3),
                  commenter,
                  "You'll be leader of the Nunya Turtles!")
    ]
  end

  # Schema:
  #
  # ```yaml
  #    hidden_identity:
  #      - first_name
  #      - last_initial
  # ```
  #
  # Struct:
  #
  # ```ruby
  #    Creator = Struct.new(
  #      :first_name, :last_initial     # simple attributes
  #    )
  # ```
  #
  let(:commenter) do
    Creator.new("Leo", "N")
  end

  # Schema:
  #
  # ```yaml
  #    post:
  #      # include multiple mixins:
  #      - with:
  #          - common_fields
  #          - engagement
  #      - title
  #      - body
  #      # If no serializer is given, all fields will be dumped to the output:
  #      - widgets
  #      - comments:
  #          # If a serializer is given, only the attributes defined in the schema will be included:
  #          serializer: comment
  #      - author:
  #          serializer: author
  #          alias: author
  #    engagement:
  #      - likes_count
  #      - comments_count
  # ```
  #
  # Structs:
  #
  # ```ruby
  #    Post = Struct.new(
  #      :id, :created_at, :updated_at, # common fields
  #      :likes_count, :comments_count, # engagement fields
  #      :title, :body,                 # simple attributes
  #      :author, :comments,            # associations w/ serializers
  #      :widgets                       # associations w/o serializers
  #    )
  #    Widget = Struct.new(
  #      :name,
  #      :quest,
  #      :favorite_color
  #    )
  # ```
  #
  let(:widgets) do
    [
      Widget.new(
        "Sir Lancelot of Camelot",
        "The Holy Grail",
        "blue"
      ).to_h.transform_keys(&:to_s),
      Widget.new(
        "Sir Gallahad of Camelot",
        "The Holy Grail",
        "blue, no...ahhhhhh!"
      ).to_h.transform_keys(&:to_s)
    ]
  end
  let(:post_1) do # rubocop:disable Naming/VariableNumber
    Post.new(
      333,
      Date.new(2024, 3, 20),
      Date.new(2025, 5, 3),
      12,
      4,
      "What I would do for another pizza",
      "Once upon a time, I owned a pizza parlor...",
      author,
      comments,
      widgets
    )
  end
  let(:post_2) do # rubocop:disable Naming/VariableNumber
    Post.new(
      444,
      Date.new(2024, 3, 20),
      Date.new(2025, 5, 3),
      33,
      53,
      "Why I should be the leader of the Ninja Turtles",
      "Four score and seven years ago...",
      author,
      comments,
      widgets
    )
  end
  let(:posts) do
    [post_1, post_2]
  end

  # Schema:
  #
  # ```yaml
  #    author:
  #      - with: common_fields
  #      - first_name
  #      - middle_initial
  #      - last_name
  #      - joined_at
  #      - total_posts_count
  # ```
  #
  # Struct:
  #
  # ```ruby
  #    Author = Struct.new(
  #      :id, :created_at, :updated_at, # common fields
  #      :first_name, :middle_initial,  # simple attributes
  #      :last_name, :joined_at,
  #      :total_posts_count
  #    )
  # ```
  #
  let(:author) do
    Author.new(
      444,
      Date.new(2024, 3, 20),
      Date.new(2025, 5, 3),
      "Don",
      "A",
      "Tello",
      Date.new(1983, 1, 1),
      400
    )
  end

  before do
    Donatello.reset!
    Donatello.setup do |c|
      c.schema_location = mock_yaml_location
    end
  end

  it "delivers complex json responses with multiple nested objects - SINGULAR" do # rubocop:disable Metrics/BlockLength
    assert_hash_equal ({
      "id" => 333,
      "created_at" => Date.new(2024, 3, 20).to_s,
      "updated_at" => Date.new(2025, 5, 3).to_s,
      "likes_count" => 12,
      "comments_count" => 4,
      "title" => "What I would do for another pizza",
      "body" => "Once upon a time, I owned a pizza parlor...",
      "author" => {
        "id" => 444,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "first_name" => "Don",
        "middle_initial" => "A",
        "last_name" => "Tello",
        "joined_at" => Date.new(1983, 1, 1).to_s,
        "total_posts_count" => 400
      },
      "comments" => [{
        "id" => 5555,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "content" => "This is a great article... not!!!@1~",
        "commenter" => {
          "first_name" => "Leo",
          "last_initial" => "N"
        }
      }, {
        "id" => 5556,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "content" => "You'll be leader of the Nunya Turtles!",
        "commenter" => {
          "first_name" => "Leo",
          "last_initial" => "N"
        }
      }],
      "widgets" => [
        {
          "name" => "Sir Lancelot of Camelot",
          "quest" => "The Holy Grail",
          "favorite_color" => "blue"
        }, {
          "name" => "Sir Gallahad of Camelot",
          "quest" => "The Holy Grail",
          "favorite_color" => "blue, no...ahhhhhh!"
        }
      ]
    }), Oj.load(serialize(post_1, :post))
  end

  it "delivers complex JSON responses with multiple nested objects - COLLECTION" do # rubocop:disable Metrics/BlockLength
    assert_hash_equal [{
      "id" => 333,
      "created_at" => Date.new(2024, 3, 20).to_s,
      "updated_at" => Date.new(2025, 5, 3).to_s,
      "likes_count" => 12,
      "comments_count" => 4,
      "title" => "What I would do for another pizza",
      "body" => "Once upon a time, I owned a pizza parlor...",
      "author" => {
        "id" => 444,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "first_name" => "Don",
        "middle_initial" => "A",
        "last_name" => "Tello",
        "joined_at" => Date.new(1983, 1, 1).to_s,
        "total_posts_count" => 400
      },
      "comments" => [{
        "id" => 5555,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "content" => "This is a great article... not!!!@1~",
        "commenter" => {
          "first_name" => "Leo",
          "last_initial" => "N"
        }
      }, {
        "id" => 5556,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "content" => "You'll be leader of the Nunya Turtles!",
        "commenter" => {
          "first_name" => "Leo",
          "last_initial" => "N"
        }
      }],
      "widgets" => [
        {
          "name" => "Sir Lancelot of Camelot",
          "quest" => "The Holy Grail",
          "favorite_color" => "blue"
        }, {
          "name" => "Sir Gallahad of Camelot",
          "quest" => "The Holy Grail",
          "favorite_color" => "blue, no...ahhhhhh!"
        }
      ]
    }, {
      "id" => 444,
      "created_at" => Date.new(2024, 3, 20).to_s,
      "updated_at" => Date.new(2025, 5, 3).to_s,
      "likes_count" => 33,
      "comments_count" => 53,
      "title" => "Why I should be the leader of the Ninja Turtles",
      "body" => "Four score and seven years ago...",
      "author" => {
        "id" => 444,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "first_name" => "Don",
        "middle_initial" => "A",
        "last_name" => "Tello",
        "joined_at" => Date.new(1983, 1, 1).to_s,
        "total_posts_count" => 400
      },
      "comments" => [{
        "id" => 5555,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "content" => "This is a great article... not!!!@1~",
        "commenter" => {
          "first_name" => "Leo",
          "last_initial" => "N"
        }
      }, {
        "id" => 5556,
        "created_at" => Date.new(2024, 3, 20).to_s,
        "updated_at" => Date.new(2025, 5, 3).to_s,
        "content" => "You'll be leader of the Nunya Turtles!",
        "commenter" => {
          "first_name" => "Leo",
          "last_initial" => "N"
        }
      }],
      "widgets" => [
        {
          "name" => "Sir Lancelot of Camelot",
          "quest" => "The Holy Grail",
          "favorite_color" => "blue"
        }, {
          "name" => "Sir Gallahad of Camelot",
          "quest" => "The Holy Grail",
          "favorite_color" => "blue, no...ahhhhhh!"
        }
      ]
    }], Oj.load(serialize([post_1, post_2], :post))
  end
end
