class ChuChuGo.Collection extends ChuChuGo.Events
  constructor: (name, db) ->
    @name = name
    @db = db

  find: (selector, opts, cb) ->
    if !cb? && _.isFunction(opts)
      cb = opts
      opts = {}
    @db.call( 'find', @name, selector, opts, (resp) => cb( @db.add(resp...) ) )

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
    @db.call( 'insert', @name, arguments... )

  update: (selector, doc, opts, cb) ->
    @db.call( 'update', @name, arguments... )

  remove: (selector, opts, cb) ->
    selector = new BSON.ObjectId(selector)  if _.isString(selector)
    selector = { _id: selector }  if selector instanceof BSON.ObjectId
    arguments[0] = selector
    @db.call( 'remove', @name, arguments... )

  observe: (selector, fields, cb) ->
    @db.call( 'observe', @name, arguments... )
