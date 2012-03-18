require 'set'

module Mongo

class FieldSet
  attr_reader :fields
  def negate?()  @negate  end

  def initialize( fields )
    @negate = fields.nil?
    if fields.is_a?(Hash)
      fields = fields.values[0]
      @negate = true  if %w(not except exclude without).include?(fields.keys[0].to_s)
    end
    @fields = Set.new Array(fields).flatten
  end

  def to_mongo
    Hash[ *fields.map { |f| [ f.to_sym, @negate ? 0 : 1 ] } ]
  end

  def all?()   fields.empty? &&  negate?  end
  def none?()  fields.empty? && !negate?  end

  def match( fields )
    fields = Set.new(fields.flatten)  unless fields.is_a?(Set)
    negate? ? (fields - @fields) : (@fields & fields)
  end

  def |( that )
    return self  if self.all? || that.none?
    return that  if that.all? || self.none?

    if self.negate?
      if that.negate?
        FieldSet.new(not: self.fields & that.fields)
      else
        FieldSet.new(not: self.fields - that.fields)
      end
    else
      if that.negate?
        FieldSet.new(not: that.fields - self.fields)
      else
        FieldSet.new(self.fields | that.fields)
      end
    end
  end

  def &( that )
    return self  if self.none? || that.all?
    return that  if that.none? || self.all?

    if self.negate?
      if that.negate?
        FieldSet.new(not: self.fields | that.fields)
      else
        FieldSet.new(that.fields - self.fields)
      end
    else
      if that.negate?
        FieldSet.new(self.fields - that.fields)
      else
        FieldSet.new(self.fields & that.fields)
      end
    end
  end
end

end
