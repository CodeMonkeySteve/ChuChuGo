# require 'underscore'
# require 'jquery-1.7.1'  # for .isPlainObject() and deep .extend()

_._isNumberStringRegExp = new RegExp('^[-+]?[0-9]*\.?[0-9]+$')

_.mixin
  isObject  : (obj) -> !_.isNull(obj) && (typeof(obj) == 'object')
  isBlank   : (obj) ->
    return true  if !obj? || (obj == false)
    return false  if (obj == true) || _.isNumber(obj) || (obj instanceof Date)
    return obj.isBlank()  if _.isFunction(obj.isBlank)
    return !obj.isPresent()  if _.isFunction(obj.isPresent)
    return (obj.length() == 0)  if _.isFunction(obj.length)
    return (obj.length == 0)  if obj.length?
    _.isEmpty(obj)

  isDefined : (obj) -> !_.isUndefined(obj)
  isPresent : (obj) -> !_.isBlank(obj)

  isNumberString : (obj) -> _.isString(obj) && _._isNumberStringRegExp.test(obj)

  _indexOf : _.indexOf
  indexOf : (array, value, isSorted = false) ->
    if _.isFunction(value)
      for el, idx in array
        return idx  if value.call(value, el)
      -1
    else
      _._indexOf(array, value, isSorted)

  except : (obj, props...) ->
    obj = owl.deepCopy(obj)
    delete obj[prop]  for prop in props
    obj

  walk: (obj, iterator, path = '') ->
    if _.isObject(obj)
      path = path + "." unless path is ''
      _.walk( value, iterator, path + attr ) for attr, value of obj
    else
      iterator( path , obj )

  # recursively merge two or more objects
  rextend: (dest, srcs...) ->
    jQuery.extend(true, dest, srcs...)

  # recursively merge two or more objects (but not arrays)
  rmerge: (dest, srcs...) ->
    dest = {}  unless _.isObject(dest)  # if recursing

    for src in srcs
      next  unless src?

      for key, val of src
        next  if dest == val  # prevent looping

        if val && jQuery.isPlainObject(val)
          cur = dest[key]
          clone = if (cur && jQuery.isPlainObject(cur))  then cur  else {}
          dest[key] = _.rmerge( clone, val )

        else if val != undefined
          dest[key] = val

    dest
