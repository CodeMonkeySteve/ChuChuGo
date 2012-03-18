class ChuChuGo.Database extends ChuChuGo.Events
  Socket = if 'MozWebSocket' in window  then MozWebSocket  else WebSocket

  constructor: (url) ->
    _.bindAll(this, '_onOpen', '_onMessage', '_onClose')
    @ws = _.extend( new Socket(url), onopen: @_onOpen, onmessage: @_onMessage, onclose: @_onClose )
    @outBuff = []
    @outReqs = {}
    @modelsById = {}

  $: (name) -> new ChuChuGo.Collection(name, this)

  call: (method, params...) ->
    cb = params.pop()  if _.isFunction(params[params.length-1])
    id = (new BSON.ObjectId()).toString()
    req = { id: id, method: method, params: params }
    @_send BSON.generate(req)
    @outReqs[id] = req

    req.cb = cb
    req.cancel = => @_send( BSON.generate(id: req.id, method: null) )
    req

  add: (models...) ->
    for model in models
      if cur = @modelsById[model.id || model._id]
        cur.set(model, silent: true)
      else
        unless model instanceof(ChuChuGo.Model)
          model = new ChuChuGo.Model(model)
        model.db = this
        @modelsById[model.id] = model
        @trigger 'add', model
    this

  _send: (msg) ->
    if @outBuff?
      @outBuff.push(msg)
    else
      @ws.send(msg)

  _onMessage: (ev) ->
    msg = BSON.parse(ev.data)
    unless msg.id
      handler = '_on'+msg.method[0].toUpperCase()+msg.method.substr(1)
      console.log "rpc: #{msg.method}(#{msg.params.join(', ')})"
      if _.isFunction(this[handler])
        this[handler].apply(this, msg.params ? [])
      else
        @trigger('notification', msg.method, msg.params)
      return

    unless req = @outReqs[msg.id]
      console.log "request (#{msg.id}): #{msg.method}(#{msg.params.join(', ')})"
      @trigger('request', msg.method, msg.params, msg.id)  
      return 

    delete @outReqs[msg.id]  #unless msg.partial
    if msg.result?
      #console.log "response (#{msg.id}): #{msg.result}"
      req.cb?(msg.result)
    else if msg.error?
      throw "RPC Error (#{req.method}(#{req.params.join(', ')})): #{msg.error}"

  _onOpen: ->
    #console.log "open"
    if @outBuff
      @ws.send(msg)  for msg in @outBuff
      delete @outBuff

  _onClose: ->
    console.log "WEBSOCKET CLOSED"
    delete @outReqs

  # _onError: (ev) ->
  #   console.log "error: #{ev.data}"

  _onInsert: (docs...) ->
    @add(docs...)

  _onUpdate: (id, mod) ->

  _onRemove: (id) ->
    if model = @modelsById[id]
      delete @modelsById[id]
      @trigger 'remove', model

