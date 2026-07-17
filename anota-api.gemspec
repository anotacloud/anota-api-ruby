# frozen_string_literal: true

require_relative "lib/anota_api"

Gem::Specification.new do |spec|
  spec.name = "anota-api"
  spec.version = AnotaApi::VERSION
  spec.authors = ["anota"]
  spec.email = ["developers@anota.cloud"]

  spec.summary = "Official Ruby client for the anota API — forms, submissions, logic, webhooks."
  spec.description = "A thin, dependency-free Ruby client over the 25-operation anota REST API: " \
                     "create and publish forms, edit fields and conditional logic, read and write " \
                     "submissions, and wire webhooks."
  spec.homepage = "https://anota.cloud/developers"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/anotacloud/anota-api-ruby"
  spec.metadata["documentation_uri"] = "https://anota.cloud/developers"

  spec.files = Dir["lib/**/*.rb", "README.md", "README.es.md", "LICENSE"]
  spec.require_paths = ["lib"]
end
