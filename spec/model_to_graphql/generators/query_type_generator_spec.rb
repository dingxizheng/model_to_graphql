# frozen_string_literal: true

require "promise.rb"

RSpec.describe ModelToGraphql::Generators::QueryTypeGenerator do
  class TestMongoidModle
    include Mongoid::Document

    field :field1, type: Integer
    field :field2, type: String
    field :field3, type: Boolean
    field :field4, type: Date
    field :field5, type: Array, element: String
    field :field6, type: Float
    field :field7, type: String, text: true
  end

  let(:fields) {
    TestMongoidModle.fields.map do |_, f|
      ModelToGraphql::Objects::Field.new(f)
    end
  }

  describe "#to_graphql_type" do
    let(:input_type) { ModelToGraphql::Generators::QueryTypeGenerator.to_graphql_type("InputType", fields) }

    it "should create 6 arguements for Integer field: field1" do
      expect(input_type.arguments.keys).to include("field1", "field1_ne", "field1_lt", "field1_gt", "field1_lte", "field1_gte")
    end

    it "should create 3 arguements for String field: field2" do
      expect(input_type.arguments.keys).to include("field2", "field2_ne", "field2_in", "field2_has")
    end

    it "should create 1 arguements for String field: field7" do
      expect(input_type.arguments.keys).not_to include("field7", "field7_ne", "field7_in")
      expect(input_type.arguments.keys).to include("field7_has")
    end
  end
end