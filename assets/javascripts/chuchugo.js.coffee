//= require 'underscore'
//= require 'backbone'

//= require 'bson/bson.js.coffee'
//= require_self
//= require_tree ./chuchugo

@ChuChuGo = {}

String::copy = (n) ->
  str = ''
  str += this  while n-- > 0
  str

Object::inspect = (ind = 0) ->
  str = @toString()
  if (str == '[object Object]') && (keys = _.keys(this)).length
    if keys.length == 1
      "{#{keys[0].inspect()}: #{@[keys[0]].inspect()}"
    else
      s = '  '.copy(++ind)
      "{\n" +
        ("#{s}#{key.inspect()}: #{@[key].inspect(ind + 1)}"  for key in _.keys(this)).join(",\n") +
      "#{'  '.copy(ind)}\n}"
  else
    str

Array::inspect = ->
  (val.inspect()  for val in this).join(', ')

