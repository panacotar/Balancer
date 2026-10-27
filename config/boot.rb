ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require_relative '../lib/runtime_secrets'
RuntimeSecrets.load!
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
