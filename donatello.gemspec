# frozen_string_literal: true

require_relative "lib/donatello/version"

Gem::Specification.new do |spec|
  spec.name = "donatello"
  spec.version = Donatello::VERSION
  spec.authors = ["Dave Rogers"]
  spec.email = ["dave@devfarm.io"]

  spec.summary = "Donatello lets you sculpt your serialized JSON according to a YAML schema."
  spec.description = "Donatello is a Ruby gem for effortlessly applying YAML-defined serialization schemas to Ruby objects, utilizing the speed of the Oj gem for optimal JSON output" # rubocop:disable Layout/LineLength
  spec.homepage = "https://github.com/devfarm-io/donatello"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/devfarm-io/donatello"
  spec.metadata["changelog_uri"] = "https://github.com/devfarm-io/donatello/CHANGELOG"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "oj", "~> 3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
