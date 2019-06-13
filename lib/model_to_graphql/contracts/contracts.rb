# frozen_string_literal: true

class MongoidModel
  def self.valid?(val)
    if val&.is_a? Class
      val < Mongoid::Document
    else
      false
    end
  end
end

class MongoidIdField
  def self.valid?(val)
    val&.instance_of?(Mongoid::Fields::Standard) && val&.name == "_id"
  end
end

class MongoidStdField
  def self.valid?(val)
    val&.instance_of? Mongoid::Fields::Standard
  end
end

class MongoidFKField
  def self.valid?(val)
    val&.instance_of? Mongoid::Fields::ForeignKey
  end
end

class MongoidLocalizedField
  def self.valid?(val)
    val&.instance_of? Mongoid::Fields::Localized
  end
end

class GraphQLResolver
  def self.valid?(val)
    if val&.is_a? Class
      val < GraphQL::Schema::Resolver
    else
      false
    end
  end
end

class GraphQLResolverPromise
  def self.valid?(val)
    val&.is_a? Promise
  end
end
