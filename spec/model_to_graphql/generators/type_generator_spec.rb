# frozen_string_literal: true

require "promise.rb"

RSpec.describe ModelToGraphql::Generators::TypeGenerator do

  let(:field2) do
    ModelToGraphql::Objects::Field.new(
      "field2",
      type: String,
      default: "default value",
      required: true
    )
  end

  let(:field3) do
    ModelToGraphql::Objects::Field.new(
      "field3",
      resolver: Promise.new
    )
  end

  describe "d" do
    subject {
      ModelToGraphql::Generators::TypeGenerator.to_graphql_type("MyType", [ field2, field3])
    }

    it "should produce one fields before field3 is resolved" do
      expect(subject.fields.keys).to eq ["field2"]
    end

    it "should produce two fields after field3 is resolved" do
      field3.resolver.fulfill(Class.new(GraphQL::Schema::Resolver))
      expect(subject.fields.keys).to eq ["field2", "field3"]
    end

  end
end