# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "bundler"

Bundler.require :default, :development, :test

require "donatello"

require "minitest"
require "minitest/autorun"
require "minitest/spec"
require "minitest/color"
require "minitest/assertions"
require "hashdiff"

# HACK: undefine method :each so we can make Struct more object-like.
# We use [Struct.new] to represent arrays of objects in the tests.
# TODO: Move to OpenStruct for tests as an alternative.
class Struct
  undef_method :each
end

module Minitest
  module Assertions
    def assert_hash_equal(expected, actual, msg = nil)
      diff = ::Hashdiff.diff(expected, actual)
      message = "Expected and actual hashes do not match:\n#{diff.pretty_inspect}"
      message = "#{msg}\n#{message}" if msg
      assert diff.empty?, message
    end
  end
end

# This adds the new assertion method to all objects, just like other Minitest assertions
Object.include Minitest::Assertions
