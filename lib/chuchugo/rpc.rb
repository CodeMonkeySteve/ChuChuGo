require 'faye/websocket'

require 'ruby-debug'

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
    @ws = Faye::WebSocket.new(env, nil, ping: 10)
    @ws.onopen, @ws.onclose, @ws.onmessage = self.method(:onOpen), self.method(:onClose), self.method(:onMessage)
    @out_reqs = {}
    @exposed = []
  end

  def call(method, *args, &cb)
    req = @out_reqs[id] = Request.new( self, method: method, args: args, &cb )
    req.call
  end

  def notify( method, *args )
#debugger
    self.onClose(nil)  unless @ws.send( { method: method, params: args }.to_ejson )
  end

  def onNotification(method, *args)
    raise NotImplError
  end

protected
  def onOpen(ev)
    Log.tagged('RPC') {  Log.info "Connect: #{@ws.env['REMOTE_ADDR']}"  }
  end

  def onClose(ev)
#debugger
    Log.tagged('RPC') {  Log.info "Disconnect: #{@ws.env['REMOTE_ADDR']}"  }
  end

  def onMessage(ev)
    begin
      msg = Mongo::ExtJSON.parse(ev.data).with_indifferent_access
      method = msg[:method].to_sym
    rescue
      Log.tagged('RPC') {  Log.error "#{$!.message}: #{ev.data}"  }
      #resp[:error] = "Unknown method: #{method.to_s.inspect}"
      @ws.send( { error: "Bad request" }.to_ejson )
      return
    end

    return onNotification(method, *msg[:params])  unless (id = msg[:id].present?)

    if req = @out_reqs[id]
      # process response
      Log.tagged('RPC') {  Log.error "(#{id}) #{$!.message}: #{ev.data}"  }
      @out_reqs.delete(id)  unless msg[:partial]
      if msg.result?
        req.cb?(data.result)
      elsif data.error?
        throw "RPC Error: #{req.method}(#{req.args.join(', ')}) -> #{data.error}"
      end

    else
       # process request
      Log.tagged('RPC') {  Log.debug "#{method}(#{msg[:params].join(', ')})"  }
      resp = { id: msg[:id].to_s }
      if exposed.include?(method)
        begin
          @cur_req, @cur_resp = req, resp
          resp[:result] = self.__send__( method, *msg[:params] )
        rescue
          resp[:error] = $!.message
          Log.tagged('RPC') {  Log.error "#{$!.message}: #{$!.backtrace.inspect}"  }
        end
      else
        resp[:error] = "Unknown method: #{method.to_s.inspect}"
      end
      @ws.send resp.to_ejson
      @cur_req = @cur_resp = nil
    end
  end
end

class Request
  attr_accessor :id, :method, :args

  def initialize(client, attrs = {}, &cb)
    @client = client
    @id = attrs[:id] || BSON::ObjectId.new
    @method, @args = attrs.values_at(:method, :args)
    @result, @error = attrs.values_at(:response, :error)
    @cb = cb
  end

  def call
    @client.instance_variable_get(:@ws).send( { id: self.id.to_s, method: method, args: args }.to_ejson )
    self
  end

  def cancel
    @client.instance_variable_get(:@ws).send( { id: self.id.to_s, method: nil }.to_ejson )
    self
  end
end

end
end
end
