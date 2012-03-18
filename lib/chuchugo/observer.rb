require 'mongo/field_set'
require 'mongo/selector'

module ChuChuGo

class Observer < Mongo::OpLog::Observer
  attr_reader :client, :collection, :selector, :fields

  def initialize( client, collection, selector, fields = nil )
    fields = Mongo::FieldSet.new(fields)  unless fields.is_a?(Mongo::FieldSet)
    selector = Mongo::Selector.new(selector)  unless selector.is_a?(Mongo::Selector)
    @client, @selector, @fields = client, selector, fields
    @doc_ids = Set.new
    super(collection)
  end

  def fetch
    opts = {}
    opts[:fields] = @fields.to_mongo  unless @fields.all?
    resp = collection.find(@selector.spec, opts).to_a
    @doc_ids = Set.new resp.map { |doc|  doc['_id'] }
    resp
  end

  def on_insert( doc )
    Log.tagged('Observer') {  Log.debug "insert (#{@collection.name}): #{doc}"  }
    raise "Missing ID in #{doc.inspect}"  unless (id = doc['_id'])
    # TODO: filter
    @doc_ids.add(id)
    @client.notify :insert, doc
  end

  def on_update( id, mod )
    Log.tagged('Observer') {  Log.debug "update (#{@collection.name} #{id}): #{mod}"  }
    # TODO: recheck filtering if update to filtering fields
    #if @doc_ids.include?(id)
    #end
    @client.notify :update, id, mod
  end

  def on_remove( id )
    Log.tagged('Observer') {  Log.debug "remove (#{@collection.name} #{id})"  }
    @client.notify :remove, id
    @doc_ids.delete(id)
  end
end

end
