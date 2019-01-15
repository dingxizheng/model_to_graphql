# frozen_string_literal: true

RSpec.describe ModelToGraphql::Definitions::ModelDefinition do
  # Define mock mongoid models
  class TestMongoidModel
    include Mongoid::Document
    include Mongoid::Timestamps

    field :rating,              type: Integer
    field :will_buy_again,      type: Boolean
    field :reason_for_use,      type: Array,    default: [], element: String
    field :reason_for_use2,     type: Array,    default: [], element: String
    field :comment,             type: String,   text: true,  sortable: false
  end

  describe "#disable_sort_on" do
    subject {
      Class.new(ModelToGraphql::Definitions::ModelDefinition) do
        define_for_model  TestMongoidModel
        disable_sort_on   :comment
      end
    }

    it "should set option sortable of a field to false" do
      unsortable = subject.merged_fields.select { |f| f.name == :comment }&.first
      expect(unsortable.sortable).to be false
    end
  end

  describe "#disable_filter_on" do
    subject {
      Class.new(ModelToGraphql::Definitions::ModelDefinition) do
        define_for_model  TestMongoidModel
        disable_filter_on :reason_for_use
      end
    }

    it "should set option filterable of a filed to false" do
      unfilterable = subject.merged_fields.select { |f| f.name == :reason_for_use }&.first
      expect(unfilterable.filterable).to be false
    end
  end

  describe "#disable_edit_on" do
    subject {
      Class.new(ModelToGraphql::Definitions::ModelDefinition) do
        define_for_model  TestMongoidModel
        disable_edit_on   :created_at
      end
    }

    it "should set option editable of a filed to false" do
      uneditable = subject.merged_fields.select { |f| f.name == :created_at }&.first
      expect(uneditable.editable).to be false
    end
  end

  describe "#exclude_fields" do
    subject {
      Class.new(ModelToGraphql::Definitions::ModelDefinition) do
        define_for_model  TestMongoidModel
        exclude_fields    :reason_for_use2, :reason_for_use
      end
    }

    it "should exclude field reason_for_use2" do
      excluded1 = subject.merged_fields.select { |f| f.name == :reason_for_use2 }&.first
      excluded2 = subject.merged_fields.select { |f| f.name == :reason_for_use }&.first
      rating    = subject.merged_fields.select { |f| f.name == :rating }&.first
      expect(excluded1).to be_nil
      expect(excluded2).to be_nil
      expect(rating).not_to be_nil
    end
  end

  describe "#field" do
    subject {
      Class.new(ModelToGraphql::Definitions::ModelDefinition) do
        define_for_model  TestMongoidModel
        field :new_field, type: String, text: true, required: true
        # Overwrite an existing field
        field :commnet,   type: String, sortable: true
      end
    }

    it "should define a new field" do
      new_field = subject.merged_fields.select { |f| f.name == :new_field }&.first
      expect(new_field).not_to be_nil
      expect(new_field.name).to be :new_field
      expect(new_field.type).to be :string
    end

    it "should overwrite the existing field" do
      commnet = subject.merged_fields.select { |f| f.name == :commnet }&.first
      expect(commnet).not_to be_nil
      expect(commnet.sortable).to be true
    end

    it "should throw exception if placeholder is not set correctly" do
      expect {
        subject.field :test_field, type: String, placeholder: "wrong"
      }.to raise_error(ContractError)
    end
  end

  describe "relations" do
  end
end
