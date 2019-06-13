# frozen_string_literal: true

require_relative "graphql_setup.rb"

# Require ORM-specific config
require_relative "mongoid_setup.rb" if defined?(Mongoid)
