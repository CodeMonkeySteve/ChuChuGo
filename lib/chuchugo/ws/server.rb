require 'mongo'
require 'chuchugo/conversions'
require 'chuchugo/ws/client'

module ChuChuGo
module Websocket

class Server
  attr_reader :db, :opts, :clients

  def initialize( app, db, opts = {} )
    @app, @db, @opts = app, db, opts
    @clients = []
  end

  def call( env )
    unless Faye::WebSocket.websocket?(env)
      return @app ? @app.call(env) : [404, {}, []]
    end

    @clients << client = Websocket::Client.new(self, env)
    client.ws.rack_response
  end
end

end
end