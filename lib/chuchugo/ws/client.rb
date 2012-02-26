require 'chuchugo/ws/rpc'

module ChuChuGo
module Websocket

class Client < RPC::Endpoint
  expose :find

  def initialize(server, env)
    @server = server
    super(env)
  end

  def find(coll, selector, opts = {})
    @server.db[coll].find(selector, opts).to_a
  end

  #def update(coll, )
  #end

protected
  def onClose(ev)
    @server.clients.delete self
  end
end

end
end
