class ChuChuGo.Collection extends ChuChuGo.Events
  constructor: (name, db) ->
    @name = name
    @db = db

  find: (selector, opts, cb) ->
    if !cb? && _.isFunction(opts)
      cb = opts
      opts = {}
    @db._call( 'find', @name, selector, opts, (resp) => cb( @db.add(resp...) ) )

  find1: (selectorOrID, opts, cb) ->
    if !cb? && _.isFunction(opts)
      cb = opts
      opts = {}

    selector = (
      if !selectorOrID?
        {}
      else if selectorOrID instanceof(BSON.ObjectId)
        { _id: selectorOrID }
      else if _.isObject(selectorOrID)
        selectorOrID
      else
        throw "selectorOrID must be a BSON.ObjectId or Hash, or null")
    @find selector, _.extend({}, opts, limit: 1), (models) -> cb?(models[0])

  insert: (docs, opts, cb) ->
    docs = [docs]  unless _.isArray(docs)
    arguments[0] = (doc.constructor.toEJSON(doc)  for doc in docs)
    @db._call( 'insert', @name, arguments... )

  update: (selector, doc, opts, cb) ->
    @db._call( 'update', @name, arguments... )

  remove: (selector, opts, cb) ->
    selector = new BSON.ObjectId(selector)  if _.isString(selector)
    selector = { _id: selector }  if selector instanceof BSON.ObjectId
    arguments[0] = selector
    @db._call( 'remove', @name, arguments... )

  observe: (selector, fields, cb) ->
    unless _.isFunction(arguments[arguments.length-1])
      arguments = Array::slice.call(arguments)
      arguments.push @db._onDBMessage
    @db._call( 'observe', @name, arguments... )
