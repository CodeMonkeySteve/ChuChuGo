require 'active_support/json'

module ExtJSON
  Conversions = []

  def self.parse(ejson)
    json = JSON.parse(ejson)
    json.class.from_ejson(json)
  end
end

class Object
  def as_ejson
    self.as_json
  end

  def to_ejson
    self.as_ejson.to_json
  end

  def self.from_ejson(json)
    json
  end
end

class BSON::ObjectId
  alias :as_ejson :as_json

  def self.from_ejson(json)
    (json.keys == %w($oid)) && BSON::ObjectId(json['$oid'])
  end
end

class BSON::DBRef
  def eql?(that)
    that.kind_of?(BSON::DBRef) && (self.namespace == that.namespace) && (self.object_id == that.object_id)
  end
  alias_method :==, :eql?

  def as_ejson
    { "$ns" => @namespace, "$id" => @object_id.to_s }
  end

  def self.from_ejson(json)
    (json.keys.sort == %w($id $ns)) && BSON::DBRef.new( json['$ns'], BSON::ObjectId(json['$id']) )
  end

  ExtJSON::Conversions << self
end

class Time
  def as_ejson
    { "$date" => (self.to_f * 1000.0).to_i }
  end

  def self.from_ejson(json)
    (json.keys == %w($date)) && Time.at(json['$date'] / 1000.0)
  end

  ExtJSON::Conversions << self
end

class Array
  def as_ejson
    self.map { |el| el.as_ejson }
  end

  def self.from_ejson(json)
    json.map do |val|
      val.class.respond_to?(:from_ejson) ? val.class.from_ejson(val) : val
    end
  end
end

class Hash
  def as_ejson
    Hash[ self.map do |key, val|
      [ key, val.as_ejson ]
    end ]
  end

  def self.from_ejson(json)
    conv_val = nil
    if json.is_a?(Hash) && ExtJSON::Conversions.any? { |conv|  conv_val = conv.from_ejson(json) }
      return conv_val
    end

    Hash[ json.map do |key, val|
      if val.class.respond_to?(:from_ejson) && (conv_val = val.class.from_ejson(val))
        val = conv_val
      end
      [ key, val ]
    end ].with_indifferent_access
  end
end