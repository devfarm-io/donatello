# Donatello

# Donatello

Donatello is a Ruby gem for effortlessly applying YAML-defined serialization schemas to Ruby objects, utilizing the speed of the Oj gem for optimal JSON output.

After spending a lot of time with GraphQL, when I started working with other types of JSON APIs, I missed being able to define my schema centrally.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'donatello'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself with:

```bash
$ gem install donatello
```

## Usage

### Defining a Schema

Create a YAML file in your Rails project (e.g., config/serialization_schema.yml) that defines your serialization schema:

```yaml
# Mixed-in field set serializers (similar concept to fragments in GraphQL)
common_fields:
  - id
  - created_at
  - updated_at

engagement:
  - likes_count
  - comments_count

# User-related serializers

public_user:
  - with: common_fields # use a single mixin
  - first_name
  - last_name

private_user:
  - with: public_user
  - access_token
  - email

author:
  - first_name
  - middle_initial
  - last_name
  - joined_at
  - total_posts_count

hidden_identity:
  - first_name
  - last_initial

# Other Objects/Entities serializers

post:
  # include multiple mixins:
  - with:
      - common_fields
      - engagement
  - title
  - body
  # If no serializer is given, all fields will be dumped to the output:
  - widgets
  - comments:
      # If a serializer is given, only the attributes defined in the schema will be included:
      - serializer: comment
  - author:
      - serializer: author
      - alias: author

comment:
  - with: common_fields
  - content
  - creator:
      # The root of this node will be "commenter" but the `creator` message will be sent to the `comment` object
      - alias: commenter
      # only include the first name, and last initial
      - serializer: hidden_identity
```

### Serializing an Object

In your controller, use Donatello to serialize an object according to the schema:

```ruby
class PostsController < ApplicationController
  # provides the "serialize" method. Note: Just put this in ApplicationController
  include Donatello

  def index
    render json: serialize(Post.all, :post)
    # or `current_user.posts` or `Post.first`, or a hash like `{ title: "Foo", ... }`

    # or `render json: { posts: serialize(Post.all) }
  end
end
```

This will produce JSON output like:

```JSON
[{
  "id": "1",
  "title": "How to Defeat Shredder, and Look Good While Doing It.",
  "body": "Once upon a time, in a sewer ...",
  "author": {
    "first_name": "Master",
    "middle_initial": "P",
    "last_name": "Splinter",
    "total_posts_count": 25
  },
  "created_at": "...",
  "updated_at": "...",
  "comments": [{
    "content": "I'll get you Splinter!!!11~!~!",
    "creator": {
      "first_name": "Shred",
      "last_initial": "R"
    }
    // ...
  },{
    // ...
  }],
  "likes_count": 444,
  "comments_count": 33
},{
  // ...
}]
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/devfarm-io/donatello].

## License

The gem is available as open source under the terms of the MIT License in this repo.
