class ChuChuGo.Collection extends Backbone.Events
  constructor: (name, database) ->
    @name = name
    @db = database

  find: (selector, opts...) ->
    callback = opts.pop()
    opts = if opts.length  then opts[0]  else {}
    @db.call( 'find', @name, selector, opts, callback )

  find1: (selectorOrID=null, opts={}) ->
    selector = (
      if !selectorOrID?
        {}
      else if selectorOrID instanceof(BSON.ObjectId)
        {_id: spec_or_object_id}
      else if _.isObject(selectorOrID)
        selectorOrID
      else
        throw "selectorOrID must be an ObjectId or Hash, or null")
    @find(selector, _.extend( {}, opts, {limit: -1} ))
