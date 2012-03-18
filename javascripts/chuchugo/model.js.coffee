class ChuChuGo.Model
  constructor: (attrs, opts) ->
    attrs ?= {}
    if defaults = @constructor.defaults
      defaults = if _.isFunction(defaults)
        defaults.call(this)
      else
        _.rextend({}, defaults)
      attrs = _.rmerge({}, defaults, attrs)

    @attributes = {}
    @prevAttrs = {}
    @set(attrs, silent: true)
    @prevAttrs = _.clone(@attributes)
    @db = opts.db  if opts?.db
    @initialize(attrs, opts)
    @id ?= new BSON.ObjectId

  initialize: ->

  get: (key) ->
    val = @attributes
    val &&= val[name]  for name in key.split('.')
    val
  $: Model::get

  set: (attrs, opts = {}) ->
    return this  unless _.size(attrs)
    if attrs instanceof Model
      @attributes = attrs.clone().attributes
      return this

    wasChanging = @_changing?.length
    @_changing ?= []

    for own key, val of attrs
      if key == '_id'
        @id = val
        continue

      cur = @get(key)
      continue  if _.isEqual(cur, val)
      @prevAttrs[key] = cur  if cur?

      path = key.split('.')
      last = path.pop()
      obj = @attributes
      for name in path
        obj[name] = {}  if _.isUndefined(obj[name])
        obj = obj[name]
      obj[last] = val
      @_changing.push(key)

    #if this.validate && !this._performValidation(attrs, options)  return false

    # Fire the "change" events, if the model has been changed.
    if !wasChanging && !opts.silent && @_changing.length #&& this.hasChanged())
      @change(opts)
    delete @_changing
    this

  # Remove an attribute from the model, firing `"change"` unless you choose
  # to silence it. `unset` is a noop if the attribute doesn't exist.
  unset: (attrs, opts = {}) ->
    return this  unless _.size(attrs)
    wasChanging = @_changing?.length
    @_changing ?= []

    for own key in attrs
      obj = @attributes
      path = key.split('.')
      last = path.pop()
      for name in path
        obj &&= obj[name]

      if obj && !_.isUndefined(val = obj[last])
        @prevAttrs[key] = val
        @_changing.push(key)
        delete obj[last]
    @change(opts)

  # Call this method to manually fire a "change" event for this model and
  # a `"change:attribute"` event for each changed attribute.
  # Calling this will cause all objects observing the model to update.
  change: (opts = {}) ->
    return unless @_changing?.length
    for attr in @_changing
      @trigger('change:' + attr, this, @prevAttrs[attr], opts)
    @trigger('change', this, options)
    delete @_changing

  @toEJSON: (ref) ->
    ref.id ?= new BSON.ObjectId
    Object.toEJSON( _.extend( {}, ref.attributes, {_id: ref.id} ) )
