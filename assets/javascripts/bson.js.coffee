//= require_self
//= require 'bson/object_id'

@BSON =
  Conversions: [Date, RegExp]

  parse: (data) ->
    ejson = JSON.parse(data)
    ejson.constructor.fromEJSON(ejson)

Object::toEJSON = ->
  ejson = {}
  for key, val of this
    unless _.isFunction(val)
      ejson[key] = if _.isObject(val) && _.isFunction(val.toEJSON)  then val.toEJSON()  else val
  ejson
Object.fromEJSON = (ejson)->
  convVal = null
  if _.isObject(ejson) && _.any( BSON.Conversions, (conv) -> convVal = conv.fromEJSON(ejson) )
    return convVal
  for key, val of ejson
    if _.isFunction(ejson.constructor.fromEJSON) && (convVal = ejson.constructor.fromEJSON(val))
      ejson[key] = convVal
  ejson

Array::toEJSON = ->
  _.map this, (val) ->
    if _.isObject(val) && _.isFunction(val.toEJSON)  then val.toEJSON()  else val
Array.fromEJSON = (ejson)->
  _.map ejson, (val) ->
    convVal = null
    if _.isObject(val) && _.any( BSON.Conversions, (conv) -> convVal = conv.fromEJSON(val) )
      convVal
    else
      val

RegExp::toEJSON = ->
  opts = ''
  opts += 'i'  if @ignoreCase
  opts += 'm'  if @multiline
  $regex: @source, $options: opts
RegExp.fromEJSON = (ejson) ->
  _.isEqual( _.keys(ejson).sort(), ['$options', '$regex'] ) && new RegExp(ejson['$regex'], ejson['$options'])

Date::toEJSON = ->
  $date: @valueOf()
Date.fromEJSON = (ejson) ->
  _.isEqual( _.keys(ejson), ['$date'] ) && new Date(Number(ejson['$date']))


class BSON.DBRef
  BSON.Conversions.push(this)

  constructor: (args...) ->
    if (args.length == 1) && _.isObject(arg) && args[0].namespace? && args[0].objectId?
      @namespace = args[0].namespace
      @objectId = args[0].objectId

    else if args.length == 2
      @namespace = args[0]
      @objectId = if args[1] instanceof(BSON.ObjectId)  then args[1]   else new BSON.ObjectId(args[1])

    else if args.length
      throw("Bad agruments: " + args)

  toEJSON: ->
    $ns: @namespace, $id: @objectId.toString()
  @fromEJSON: (ejson) ->
    _.isEqual( _.keys(ejson).sort(), ['$id', '$ns'] ) && new DBRef(ejson['$ns'], ejson['$id'])
