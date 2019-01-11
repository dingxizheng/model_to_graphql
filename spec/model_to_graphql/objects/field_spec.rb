# frozen_string_literal: true

RSpec.describe ModelToGraphql::Objects::Field do

  # Define mock mongoid models
  class User
    include Mongoid::Document
    include Mongoid::Timestamps
    field :external_id,   type: String
    field :age,           type: Integer
    field :gender,        type: String
    field :app_data,      type: Hash,    default: {},  filterable: false
    field :reviews_count, type: Integer, default: 0, editable: false

    has_many :reviews
  end

  # Define mock mongoid models
  class Review
    include Mongoid::Document
    include Mongoid::Timestamps

    field :average_consumption, type: Array,    default: [0], element: Float
    field :rating,              type: Integer
    field :will_buy_again,      type: Boolean
    field :reason_for_use,      type: Array,    default: [], element: String
    field :positive_effects,    type: Array,    default: [], element: String
    field :negative_effects,    type: Array,    default: [], element: String
    field :comment,             type: String,   text: true,  sortable: false

    belongs_to :reviewer, inverse_of: :reviews, class_name: "User"
  end

  context "Handle normal field" do
    let(:normal_field) { Review.fields["reason_for_use"] }
    let(:field) { ModelToGraphql::Objects::Field.new(normal_field) }
    let(:field_with_sortable) { ModelToGraphql::Objects::Field.new(Review.fields["comment"]) }

    it "should convert type class to symbol" do
      expect(field.type).to eq :array
    end

    it "should convert element type to symbol" do
      expect(field.element).to eq :string
    end

    it "should handle sortable option" do
      expect(field_with_sortable.sortable).to be_falsey
    end
  end

  context "Handler ForeignKey field" do
    let(:fk_field) { Review.fields["reviewer_id"] }
    let(:field) { ModelToGraphql::Objects::Field.new(fk_field) }

    it "should return foreign classes" do
      expect(field.foreign_class).to eq [User]
      expect(field.type).to eq :object_id
      expect(field.name).to eq :reviewer_id
      expect(field.foreign_key).to be true
    end
  end

  context "Create field manually" do
    it "should raise an error if options are not incorrect" do
      expect {
        ModelToGraphql::Objects::Field.new("id", type: "String")
      }.to raise_error(ContractError, /With Contract: String, Hash => Any/)
    end
  end
end
