require 'set'

module Mongo

class Selector
  Error = RuntimeError
  Operators = %w().map { |o|  "$#{o}".to_sym }.freeze

  attr_reader :spec

  def initialize( spec )
    spec = spec.spec.dup  if spec.is_a?(Selector)
    if spec
      @spec = spec.dup
      # FIXME: create #match? lazily
      @spec_expr_s = to_expr_s(@spec)
      self.instance_eval "def match?( doc, fields = nil ) ; #{@spec_expr_s} ; end"
    end
  end

  def =~(that)  match?(that)  end
  delegate :inspect, :to_s, to: :spec

  # def self.type_cast( value )
  #   self.new BSON.unescape(value)
  # end
  # def to_mongo
  #   BSON.escape(@spec)
  # end

protected
  def []( doc, *keys )
    v = doc
    keys.all? do |k|
      begin
        v = v[k] || v[k.to_s]
        !v.nil?
      rescue Exception
        false
      end
    end ? v : nil
  end

  def to_expr_s( spec )
    exprs = []
    spec.each_pair  do |key, spec|
      val_s = "self[doc,#{key.to_s.split('.').map { |k| k.to_sym.inspect }.join(',')}]"
      exprs +=
         if (Hash === spec) && spec.all? { |k, c|  k.to_s[0] == '$' }
        ops_to_expr_s( val_s, spec )
      elsif key.to_s[0] == '$'
        ops_to_expr_s( nil, key => spec )
      elsif Regexp === spec
        ["#{val_s} =~ #{spec.inspect}"]
      else
        ["#{val_s} == #{spec.inspect}"]
      end
    end
    (exprs.size == 1) ? exprs.first : exprs.map { |ex|  "(#{ex})" }.join(' && ')
  end

  def ops_to_expr_s( val_s, ops )
    ops.map  do |op, arg|
      arg_s = arg.inspect
      case op.to_sym
        # scalar, scalar
        when :$gt  then  "#{val_s} > #{arg_s}"
        when :$lt  then  "#{val_s} < #{arg_s}"
        when :$gte then  "#{val_s} >= #{arg_s}"
        when :$lte then  "#{val_s} <= #{arg_s}"
        when :$ne  then  "#{val_s} != #{arg_s}"

        # scalar, boolen
        when :$exists then  "#{('!' if arg)}#{val_s}.nil?"

        # scalar/array, array(scalar)
        when :$in  then  "!(Set.new(Array(#{arg_s})) & Set.new(Array(#{val_s}))).empty?"
        when :$nin then  " (Set.new(Array(#{arg_s})) & Set.new(Array(#{val_s}))).empty?"
        when :$all then   "Set.new(Array(#{arg_s})).subset?( Set.new(Array(#{val_s})) )"

        # scalr, array(expr)
        when :$or  then  arg.map { |a|  "(#{to_expr_s(a)})" }.join(' || ')
        when :$nor then  arg.map { |a| "!(#{to_expr_s(a)})" }.join(' && ')

        # array(), integer
        when :$size then  "#{val_s}.size == #{arg_s}"

        # array(), expr
        when :$elemMatch then  "#{val_s}.any? { |doc|  #{to_expr_s(arg)} }"

        # (), expr
        when :$not then  "!(#{to_expr_s(arg)})"

        #:$type
        #:$where
      end
    end
  end
end

end