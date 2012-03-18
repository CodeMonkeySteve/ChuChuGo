require 'mongo/oplog'
require 'mongo/ext_json'
require 'chuchugo/client'

module ChuChuGo
module Websocket

class Server
  attr_reader :db, :opts, :clients
  attr_reader :oplog

  def initialize( app, db, opts = {} )
    Faye::WebSocket.load_adapter('thin')
    @app, @db, @opts = app, db, opts
    @clients = []
  end

  def call( env )
    unless Faye::WebSocket.websocket?(env)
      return @app ? @app.call(env) : [404, {}, []]
    end

    # defer monitoring oplog until first client connects
    @oplog ||= Mongo::OpLog.new(@db.connection).start(opts[:interval])

    @clients << client = Websocket::Client.new(self, env)
    client.ws.rack_response
  end
end

end
end
