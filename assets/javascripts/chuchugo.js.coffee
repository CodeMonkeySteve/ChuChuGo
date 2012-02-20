//= require 'underscore-1.3.1'
//= require 'backbone-0.9.0'
//= require 'bson'
//= require_self

@ChuChuGo = {}

class ChuChuGo.Database
  constructor: (url) ->
    @url = url
    @initialize.apply(this, arguments)

  initialize: ->


class ChuChuGo.Collection
  constructor: (name, database) ->
    @name = name
    @db = database
    @initialize.apply(this, arguments)

  initialize: ->

  find: (query, fields, success) ->
    opts = {}
    if fields?
      opts.fields = if _.isArray(fields)  then {include: fields}  else fields

    @cmd 'find', [query, opts]

  cmd: (op, args..., opts = {}) ->
    jQuery.ajax
      url: "#{@db.url}/#{@name}/#{op}"
      dataType: 'json'
      success = (data, status, xhr) ->
        resp = ExtJSON.parse(data)

class ChuChuGo.Model

class ChuChuGo.DataView
  