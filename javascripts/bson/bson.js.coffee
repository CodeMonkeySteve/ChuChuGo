//= require_self
//= require_directory .

@BSON =
  Conversions: [Date, RegExp]

  parse: (data) ->
    ejson = JSON.parse(data)
    ejson.constructor.fromEJSON(ejson)

  generate: (val) ->
    JSON.stringify( val.constructor.toEJSON(val) )

Object.toEJSON = (obj) ->
  ejson = {}
  for key, val of obj
    unless _.isFunction(val)
      ejson[key] = if _.isObject(val) && (type = val.constructor) && _.isFunction(type.toEJSON)  then type.toEJSON(val)  else val
  ejson
Object.fromEJSON = (ejson) ->
  convVal = null
  if _.isObject(ejson) && _.any( BSON.Conversions, (conv) -> convVal = conv.fromEJSON(ejson) )
    return convVal
  for key, val of ejson
    continue unless type = val?.constructor
    if _.isFunction(type.fromEJSON) && (convVal = type.fromEJSON(val))
      ejson[key] = convVal
  ejson

Array.toEJSON = (arr) ->
  _.map arr, (val) ->
    if _.isObject(val) && (type = val.constructor) && _.isFunction(type.toEJSON)  then type.toEJSON(val)  else val
Array.fromEJSON = (ejson) ->
  _.map ejson, (val) ->
    convVal = null
    if (_.isObject(val) && _.any( BSON.Conversions, (conv) -> convVal = conv.fromEJSON(val) )) ||
       (_.isFunction(val.constructor.fromEJSON) && (convVal = val.constructor.fromEJSON(val)))
      convVal
    else
      val

RegExp.toEJSON = (re) ->
  opts = ''
  opts += 'i'  if re.ignoreCase
  opts += 'm'  if re.multiline
  $regex: re.source, $options: opts
RegExp.fromEJSON = (ejson) ->
  _.isEqual( _.keys(ejson).sort(), ['$options', '$regex'] ) && new RegExp(ejson['$regex'], ejson['$options'])

Date.toEJSON = (d) ->
  $date: d.valueOf()
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

  @toEJSON: (ref) ->
    $ns: ref.namespace, $id: ref.objectId.toString()
  @fromEJSON: (ejson) ->
    _.isEqual( _.keys(ejson).sort(), ['$id', '$ns'] ) && new DBRef(ejson['$ns'], ejson['$id'])
