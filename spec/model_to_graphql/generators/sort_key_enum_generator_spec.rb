# frozen_string_literal: true

require "promise.rb"

RSpec.describe ModelToGraphql::Generators::SortKeyEnumGenerator do

  let(:sortable_field) do
    ModelToGraphql::Objects::Field.new(
      "field1",
      type: String,
      sortable: true
    )
  end

  let(:unsortable_field) do
    ModelToGraphql::Objects::Field.new(
      "field2",
      type: Array,
      sortable: false
    )
  end

  describe "#to_graphql_type" do
    subject {
      ModelToGraphql::Generators::SortKeyEnumGenerator.to_graphql_enum("MyEnum", [sortable_field, unsortable_field])
    }

    it "should be a graphql enum class" do
      expect(subject.new).to be_a(GraphQL::Schema::Enum)
    end

    it "should have graphql_name equals to MyEnum" do
      expect(subject.graphql_name).to eq "MyEnum"
    end

    it "should only generate enum values for sortable fields" do
      expect(subject.values.keys).to eq ["field1_asc", "field1_desc"]
    end
  end
end