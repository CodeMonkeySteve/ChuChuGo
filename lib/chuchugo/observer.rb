require 'mongo/field_set'
require 'mongo/selector'

module ChuChuGo

class Observer < Mongo::OpLog::Observer
  attr_reader :req, :collection, :selector, :fields

  def initialize( req, collection, selector, fields = nil )
    fields = Mongo::FieldSet.new(fields)  unless fields.is_a?(Mongo::FieldSet)
    selector = Mongo::Selector.new(selector)  unless selector.is_a?(Mongo::Selector)
    @req, @selector, @fields = req, selector, fields
    @doc_ids = Set.new
    super(collection)
  end

  def fetch!
    opts = {}
    opts[:fields] = @fields.to_mongo  unless @fields.all?
    resp = collection.find(@selector.spec, opts).to_a
    @doc_ids = Set.new resp.map { |doc|  doc['_id'] }
Log.tagged('Observer') {  Log.debug "ids: #{@doc_ids.to_a.map(&:to_s).join(', ')}"  }
    resp
  end

  def on_insert( doc )
    Log.tagged('Observer') {  Log.debug "insert (#{@collection.name}): #{doc}"  }
    raise "Missing ID in #{doc.inspect}"  unless (id = doc['_id'])

    if @selector.match?(doc)
      @doc_ids.add(id)
Log.tagged('Observer') {  Log.debug "ids: #{@doc_ids.to_a.map(&:to_s).join(', ')}"  }
      @req.respond([ :insert, doc ])
    end
  end

  def on_update( id, mod )
    Log.tagged('Observer') {  Log.debug "update (#{@collection.name} #{id}): #{mod}"  }

    if @doc_ids.include?(id)
      # TODO: recheck filtering if update to filtering fields
      @req.respond([ :update, id, mod ])
    end
  end

  def on_remove( id )
    if @doc_ids.include?(id)
      Log.tagged('Observer') {  Log.debug "remove (#{@collection.name} #{id})"  }
      @req.respond([ :remove, id ])
      @doc_ids.delete(id)
Log.tagged('Observer') {  Log.debug "ids: #{@doc_ids.to_a.map(&:to_s).join(', ')}"  }
    end
  end
end

end
