# ChuChuGo (c) 2012 Steve Sloan
# ChuChuGo may be freely distributed under the MIT license.

# Portions from Backbone.js 0.9.0:
#   (c) 2010-2012 Jeremy Ashkenas, DocumentCloud Inc.
#   Backbone may be freely distributed under the MIT license.

//= require 'underscore_ext'
//= require 'bson/bson.js.coffee'
//= require_self
//= require 'chuchugo/events'
//= require 'chuchugo/model'
//= require 'chuchugo/collection'
//= require 'chuchugo/database'
//= require_tree './chuchugo'

@ChuChuGo = {}

String::copy = (n) ->
  str = ''
  str += this  while n-- > 0
  str
