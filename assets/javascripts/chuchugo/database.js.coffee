class ChuChuGo.Database extends Backbone.Events
  Socket = if 'MozWebSocket' in window  then MozWebSocket  else WebSocket

  constructor: (url) ->
    _.bindAll(this, '_onOpen', '_onMessage', '_onClose')
    @ws = _.extend( new Socket(url), onopen: @_onOpen, onmessage: @_onMessage, onclose: @_onClose )
    @outBuff = []
    @outReqs = {}

  $: (name) -> new ChuChuGo.Collection(name, this)

  call: (method, params...) ->
    throw "Missing callback" unless callback = params.pop()
    id = new BSON.ObjectId().toString()
    req = { id: id, method: method, params: params }
    @_send JSON.stringify(req)
    @outReqs[id] = req

    req.callback = callback
    req.cancel = => @_send(JSON.stringify( id: req.id, method: null ))
    #console.log "call(#{method}, #{params.inspect()})"

  _send: (msg) ->
    if @outBuff?
      @outBuff.push(msg)
    else
      @ws.send(msg)

  _onMessage: (ev) ->
    msg = BSON.parse(ev.data)
    #console.log "msg: #{msg.inspect()}"
    return @trigger('notification', msg.method, msg.params)  unless msg.id
    return @trigger('request',      msg.method, msg.params, msg.id)  unless req = @outReqs[msg.id]

    delete @outReqs[msg.id]  unless msg.partial
    if msg.result?
      req.callback?(msg.result)
    else if msg.error?
      throw "RPC Error (#{req.method}(#{req.params.join(', ')})): #{msg.error}"

  _onOpen: ->
    #console.log "open"
    if @outBuff
      @ws.send(msg)  for msg in @outBuff
      delete @outBuff

  _onClose: ->
    #console.log "close"
    delete @outReqs
    delete @channels

  # _onError: (ev) ->
  #   console.log "error: #{ev.data}"
