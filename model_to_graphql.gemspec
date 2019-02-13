# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "model_to_graphql/version"

Gem::Specification.new do |spec|
  spec.name          = "model_to_graphql"
  spec.version       = ModelToGraphql::VERSION
  spec.authors       = ["dingxizheng"]
  spec.email         = ["dingxizheng@gmail.com"]

  spec.summary       = "Convert model definitions into graphql queries and mutations"
  spec.description   = "Convert model definitions into graphql queries and mutations"
  spec.homepage      = "https://github.com/dingxizheng/model_to_graphql.git"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/dingxizheng/model_to_graphql.git"
    spec.metadata["changelog_uri"] = "https://github.com/dingxizheng/README.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "graphql", ">= 0.8", "< 2"
  spec.add_runtime_dependency "graphql-batch"
  spec.add_runtime_dependency "graphql-guard"
  spec.add_runtime_dependency "contracts"
  spec.add_runtime_dependency "require_all"
  spec.add_runtime_dependency "promise.rb"
  
  spec.add_development_dependency "mongoid", "~> 5.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake",    "~> 10.0"
  spec.add_development_dependency "rspec",   "~> 3.0"
  spec.add_development_dependency "solargraph"
end
