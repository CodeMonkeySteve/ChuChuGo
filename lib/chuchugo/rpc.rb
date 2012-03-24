require 'faye/websocket'

module ChuChuGo
module Websocket
module RPC

class Endpoint
  cattr_accessor :exposed
  def self.expose(*methods)
    self.exposed = ((self.exposed || []) + methods.map(&:to_sym)).uniq
  end

  attr_accessor :ws, :in_req, :out_req

  def initialize(env)
    @ws = Faye::WebSocket.new(env, nil, ping: 5)
    @ws.onopen, @ws.onclose, @ws.onmessage = self.method(:on_open), self.method(:on_close), self.method(:on_message)
    @in_reqs = {}
    @out_reqs = {}
    @exposed = []
  end

  def call(method, *args, &cb)
    @out_req = @out_reqs[id] = Request.new( self, method: method, args: args, &cb )
    @out_req.call
  end

  def notify( method, *args )
    self.on_close(nil)  unless @ws.send( { method: method, params: args }.to_ejson )
  end

  def on_notification(method, *args)
    raise NotImplementedError
  end

protected
  def on_open(ev)
    Log.tagged('RPC') {  Log.info "Connect: #{@ws.env['REMOTE_ADDR']}"  }
  end

  def on_close(ev)
    Log.tagged('RPC') {  Log.info "Disconnect: #{@ws.env['REMOTE_ADDR']}"  }
    @in_reqs.values.each { |req|  req.on_cancelled }
  end

  def on_message(ev)
    begin
      msg = Mongo::ExtJSON.parse(ev.data).with_indifferent_access
    rescue
      Log.tagged('RPC') {  Log.error "#{$!.message}: #{ev.data}"  }
      @ws.send( { error: "Bad request" }.to_ejson )
      return
    end
    id, method = msg[:id], msg[:method].try(:to_sym)

    if id.blank?
      on_notification( method, *msg[:params] )

    elsif @out_req = req = @out_reqs[id]
      Log.tagged('RPC') {  Log.error "response (#{id}): #{req}"  }

      @out_reqs.delete(id)  unless msg[:partial]
      if msg.result
        req.cb?(data.result)
      elsif msg.error
        throw "RPC Error: #{req.method}(#{req.params.join(', ')}) -> #{data.error}"
      end
      @out_req = nil

    elsif (@in_req = req = @in_reqs[id]) && method.nil?
      Log.tagged('RPC') {  Log.debug "#{id}: #{req.method}(#{(req.params || []).join(', ')}) cancel"  }
      req.on_cancelled()
      @in_req = nil

    else
      @in_reqs[id] = @in_req = req = Request.new(self, msg)
      Log.tagged('RPC') {  Log.debug "#{id}: #{req.method}(#{(req.params || []).join(', ')})"  }

      res = nil
      if exposed.include?(req.method)
        begin
          res = self.__send__( method, *msg[:params] )
          req.respond(res)  unless req.responded?
        rescue
          Log.tagged('RPC') {  Log.error "#{$!.message}:\n#{$!.backtrace.join("\n")}"  }
          req.error $!.message
        end
      else
        req.error "Unknown method: #{method.to_s.inspect}"
      end
      @in_req = nil
      res
    end
  end
end

class Request
  attr_accessor :id, :method, :params

  def initialize( endpt, attrs = {}, &cb )
    @endpt = endpt
    attrs = attrs.with_indifferent_access
    @id = attrs[:id] || BSON::ObjectId.new
    @method = attrs[:method].try(:to_sym)
    @params = attrs[:params]
    @cb = cb
  end

  # incoming
  def responded?()  @responded  end
  def completed?()  @completed  end

  def respond( result, opts = {} )
    opts[:partial] = true  unless opts.include?(:partial)
    opts[:result] = result  unless opts.include?(:result)
    @endpt.ws.send( { id: self.id.to_s }.merge(opts).to_ejson )
    @responded = true
    self
  end

  def complete( result )
    respond(result, partial: false)
    self.finish(:@in_reqs)
    @completed = true
  end

  def error( msg )
    @endpt.ws.send( { id: self.id.to_s, error: msg }.to_ejson )
  end

  def on_cancelled
    self.finish(:@in_reqs)
  end

  # outgoing
  def call
    @endpt.ws.send( { id: self.id.to_s, method: self.method, params: self.params }.to_ejson )
    @endpt.instance_variable_get(:@out_reqs)[self.id] = self
    self
  end

  def cancel
    @endpt.ws.send( { id: self.id.to_s, method: nil }.to_ejson )
    self.finish(:@out_reqs)
    self
  end

  def on_reply( result, complete )
    @cb.call(result)  if @cb && result
    self.finish(:@out_reqs)  if complete
  end

protected
  def finish( queue )
    @endpt.instance_variable_get(queue).delete(self.id)
  end
end

end
end
end
