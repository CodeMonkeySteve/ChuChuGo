require 'chuchugo/rpc'
require 'chuchugo/observer'

module ChuChuGo
module Websocket

class Client < RPC::Endpoint

  def initialize(server, env)
    @server = server
    @observers = {}
    super(env)
  end

  expose :find
  def find(coll, selector, opts = {})
    @server.db[coll].find(selector, opts).to_a
  end

  expose :insert
  def insert(coll, docs, opts = {})
    docs = [docs]  unless docs.is_a?(Array)
    rev = BSON::ObjectId.new
    #docs.each { |doc| doc['_rev'] = rev }
    @server.db[coll].insert docs, opts
  end

  expose :update
  def update(coll, selector, doc, opts = {})
    #doc['_rev'] = BSON::ObjectId.new
    selector = BSON::ObjectId(selector)  if selector.is_a?(String)
    selector = { _id: selector }         if selector.is_a?(BSON::ObjectId)
    @server.db[coll].update selector, doc, opts
  end

  expose :remove
  def remove(coll, selector, opts = {})
    selector = BSON::ObjectId(selector)  if selector.is_a?(String)
    selector = { _id: selector }         if selector.is_a?(BSON::ObjectId)
    @server.db[coll].remove selector, opts
  end

  expose :observe
  def observe(coll, spec, fields = nil)
    coll = @server.db[coll]
    return nil  if @observers.include?( [spec,fields] )
    observer = @observers[[spec,fields]] = ChuChuGo::Observer.new(self.in_req, coll, spec, fields)
    res = observer.fetch!
    oplog = @server.oplog
    oplog.observe observer
    in_req.define_singleton_method :on_cancelled do
      super()
      oplog.ignore observer
    end
    in_req.respond([ :insert, *res.to_a ])
  end

protected
  def on_close(ev)
    @observers.values.flatten.each { |o|  @server.oplog.ignore(o) }
    @observers.clear
    @server.clients.delete self
    super
  end
end

end
end
