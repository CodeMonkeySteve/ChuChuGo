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
    @server.db[coll].insert(docs, opts)
  end

  expose :update
  def update(coll, selector, doc, opts = {})
    #doc['_rev'] = BSON::ObjectId.new
    @server.db[coll].update selector, doc, opts
  end

  expose :remove
  def remove(coll, selector, opts = {})
    @server.db[coll].remove selector, opts
  end

  expose :observe
  def observe(coll, spec, fields = nil)
    coll = @server.db[coll]

    return nil  if @observers.include?( [spec,fields] )
    observer = @observers[[spec,fields]] = ChuChuGo::Observer.new(self, coll, spec, fields)
    resp = observer.fetch
    @server.oplog.observe observer
    EM.next_tick { self.notify( :insert, *resp.to_a ) }
    true
  end

protected
  def onClose(ev)
    @observers.values.flatten.each { |o|  @server.oplog.ignore(o) }
    @observers.clear
    @server.clients.delete self
    super
  end
end

end
end
