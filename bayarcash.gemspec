# frozen_string_literal: true

require_relative "lib/bayarcash/version"

Gem::Specification.new do |spec|
  spec.name          = "bayarcash"
  spec.version       = Bayarcash::VERSION
  spec.authors       = ["Web Impian"]
  spec.email         = ["support@webimpian.com"]

  spec.summary       = "Ruby SDK for the Bayarcash payment gateway."
  spec.description   = "An expressive, framework-agnostic Ruby client for the Bayarcash " \
                       "Payment Gateway API. Supports API v2 (default) and v3, checksum " \
                       "generation, callback verification, FPX Direct Debit, and Manual Bank Transfer."
  spec.homepage      = "https://bayarcash.com/"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bayarcash/ruby-sdk"
  spec.metadata["changelog_uri"]   = "https://github.com/bayarcash/ruby-sdk/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("lib/**/*.rb") + %w[README.md CHANGELOG.md LICENSE bayarcash.gemspec]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 1.10", "< 3.0"
  spec.add_dependency "faraday-multipart", ">= 1.0", "< 2.0"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "rake", "~> 13.0"
end
