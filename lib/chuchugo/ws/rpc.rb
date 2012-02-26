require 'faye/websocket'

module ChuChuGo
module Websocket
module RPC

class Endpoint
  cattr_accessor :exposed
  def self.expose(*methods)
    self.exposed = ((self.exposed || []) + methods.map(&:to_sym)).uniq
  end

  attr_accessor :ws
  def initialize(env)
    @ws = Faye::WebSocket.new(env)
    @ws.onmessage, @ws.onclose = self.method(:onMessage), self.method(:onClose)
    @out_reqs = {}
    @exposed = []
  end

  def call(method, *args, &callback)
    req = @out_reqs[id] = Request.new( self, method: method, args: args, &callback )
    req.call
  end

  def onNotification(method, *args)
    raise NotImplError
  end

protected
  def onMessage(ev)
    msg = ExtJSON.parse(ev.data).with_indifferent_access
    method = msg[:method].to_sym
    return onNotification(method, *msg[:params])  unless (id = msg[:id].present?)

    if req = @out_reqs[id]
      # process response
      @out_reqs.delete(id)  unless msg[:partial]
      if msg.result?
        req.callback?(data.result)
      elsif data.error?
        throw "RPC Error: #{req.method}(#{req.args.join(', ')}) -> #{data.error}"
      end

    else
       # process request
      resp = { id: msg[:id].to_s }
      if exposed.include?(method)
        begin
          resp[:result] = self.__send__( method, *msg[:params] )
        rescue
          resp[:error] = $!.message
puts $!.message, $!.backtrace
        end
      else
        resp[:error] = "Unknown method: #{method.to_s.inspect}"
      end
      @ws.send JSON.generate( resp )
    end
  end

  def onClose(ev)
  end
end

class Request
  attr_accessor :id, :method, :args

  def initialize(client, attrs = {}, &callback)
    @client = client
    @id = attrs[:id] || BSON::ObjectId.new
    @method, @args = attrs.values_at(:method, :args)
    @result, @error = attrs.values_at(:response, :error)
    @callback = callback
  end

  def call
    @client.instance_variable_get(:@ws).send( JSON.generate( id: self.id.to_s, method: method, args: args ) )
    self
  end

  def cancel
    @client.instance_variable_get(:@ws).send( JSON.generate( id: self.id.to_s, method: nil ) )
    self
  end
end

end
end
end
