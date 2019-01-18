# frozen_string_literal: true

module ModelToGraphql
  module ORM
    module MongoidSettings
      TYPE_MAPPINGS = {
        array: Array,
        big_decimal: BigDecimal,
        binary: BSON::Binary,
        boolean: Mongoid::Boolean,
        date: Date,
        date_time: DateTime,
        float: Float,
        hash: Hash,
        integer: Integer,
        object_id: BSON::ObjectId,
        range: Range,
        regexp: Regexp,
        set: Set,
        string: String,
        symbol: Symbol,
        object: Object,
        time: Time
      }.freeze
    end
  end
end
