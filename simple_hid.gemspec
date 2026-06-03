# frozen_string_literal: true

require_relative "lib/simple_hid/version"

Gem::Specification.new do |spec|
  spec.name          = "simple_hid"
  spec.version       = SimpleHID::VERSION
  spec.authors       = ["Jesse Fullam"]
  spec.email         = []

  spec.summary       = "Minimal FFI-based HIDAPI wrapper for Ruby, inspired by Python's hid library."
  spec.description   = "Provides simple device enumeration by VID/PID/usage and write-only communication for HID devices."
  spec.homepage      = "https://github.com/bell-arch/Simple_HID"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.6"

  spec.files         = Dir[
    "lib/**/*.rb",
    "README.md",
    "LICENCE"
  ]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ffi", ">= 1.15", "< 2.0"

  # Dev dependencies
  spec.add_development_dependency "rake", ">= 13", "< 14"
  spec.add_development_dependency "bundler", ">= 2.3", "< 3.0"

  spec.metadata = {
    "source_code_uri" => "https://github.com/bell-arch/Simple_HID",
    "changelog_uri" => "https://github.com/bell-arch/Simple_HID/releases",
    "rubygems_mfa_required" => "true"
  }
end 