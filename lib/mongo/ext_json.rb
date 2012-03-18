require 'bson'
require 'active_support/json'

# Extended JSON conversions (see http://www.mongodb.org/display/DOCS/Mongo+Extended+JSON)
#   * Binary:    TODO
#   * Timestamp: TODO
#   * Date:      done
#   * Regex:     done
#   * ObjectId:  done
#   * DBRef:     done

module Mongo
module ExtJSON
  Conversions = []

  def self.parse(data)
    ejson = JSON.parse(data)
    ejson.class.from_ejson(ejson)
  end
end
end

class Object
  def as_ejson
    self.as_json
  end

  def to_ejson
    self.as_ejson.to_json
  end

  def self.from_ejson(ejson)
    ejson
  end
end

class Time
  def as_ejson
    { '$date' => (self.to_f * 1000.0).to_i }
  end

  def self.from_ejson(ejson)
    (ejson.keys == %w($date)) && Time.at(ejson['$date'] / 1000.0)
  end

  Mongo::ExtJSON::Conversions << self
end

class Regexp
  def as_ejson
    opts = ''
    opts << 'i'  if self.options & Regexp::IGNORECASE
    opts << 'm'  if self.options & Regexp::MULTILINE
    { '$regex' => self.source, '$options' => opts }
  end

  def self.from_ejson(ejson)
    if ejson.keys.sort == %w($options $regex)
      opts = 0
      opts |= Regexp::IGNORECASE  if ejson['$options'].include?('i')
      opts |= Regexp::MULTILINE   if ejson['$options'].include?('m')
      Regexp.new(ejson['$regex'], opts)
    end
  end

  Mongo::ExtJSON::Conversions << self
end

class BSON::ObjectId
  alias :as_ejson :as_json

  def self.from_ejson(ejson)
    (ejson.keys == %w($oid)) && BSON::ObjectId(ejson['$oid'])
  end

  Mongo::ExtJSON::Conversions << self
end

class BSON::DBRef
  def eql?(that)
    that.kind_of?(BSON::DBRef) && (self.namespace == that.namespace) && (self.object_id == that.object_id)
  end
  alias_method :==, :eql?

  def as_ejson
    { '$ns' => @namespace, '$id' => @object_id.to_s }
  end

  def self.from_ejson(ejson)
    (ejson.keys.sort == %w($id $ns)) && BSON::DBRef.new( ejson['$ns'], BSON::ObjectId(ejson['$id']) )
  end

  Mongo::ExtJSON::Conversions << self
end

class Array
  def as_ejson
    self.map { |el| el.as_ejson }
  end

  def self.from_ejson(ejson)
    ejson.map do |val|
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

  def self.from_ejson(ejson)
    conv_val = nil
    if ejson.is_a?(Hash) && Mongo::ExtJSON::Conversions.any? { |conv|  conv_val = conv.from_ejson(ejson) }
      return conv_val
    end

    Hash[ ejson.map do |key, val|
      if val.class.respond_to?(:from_ejson) && (conv_val = val.class.from_ejson(val))
        val = conv_val
      end
      [ key, val ]
    end ].with_indifferent_access
  end
end
