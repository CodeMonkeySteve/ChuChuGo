class ChuChuGo.Events
  # Bind an event, specified by a string name, `ev`, to a `callback`
  # function. Passing `"all"` will bind the callback to all events fired.
  on: (events, callback, context) ->
    events = events.split(/\s+/)
    calls = @_callbacks || (@_callbacks = {})
    while ev = events.shift()
      # Create an immutable callback list, allowing traversal during
      # modification.  The tail is an empty object that will always be used
      # as the next node.
      list = calls[ev] || (calls[ev] = {})
      tail = list.tail || (list.tail = list.next = {})
      tail.callback = callback
      tail.context = context
      list.tail = tail.next = {}
    this

  # Remove one or many callbacks. If `context` is null, removes all callbacks
  # with that function. If `callback` is null, removes all callbacks for the
  # event. If `ev` is null, removes all bound callbacks for all events.
  off: (events, callback, context) ->
    if !events
      delete @_callbacks
    else if calls = @_callbacks
      events = events.split(/\s+/)
      while ev = events.shift()
        node = calls[ev]
        delete calls[ev]
        continue unless callback && node

        # Create a new list, omitting the indicated event/context pairs.
        while (node = node.next) && node.next
          continue if (node.callback == callback) && (!context || (node.context == context))
          @on(ev, node.callback, node.context)
    this

  # Trigger an event, firing all bound callbacks. Callbacks are passed the
  # same arguments as `trigger` is, apart from the event name.
  # Listening for `"all"` passes the true event name as the first argument.
  trigger: (events, rest...) ->
    return this  unless calls = @_callbacks
    all = calls.all
    (events = events.split(/\s+/)).push(null)

    # Save references to the current heads & tails.
    while event = events.shift()
      if all  then events.push( next: all.next, tail: all.tail, event: event )
      continue unless node = calls[event]
      events.push( next: node.next, tail: node.tail )

    # Traverse each list, stopping when the saved tail is reached.
    while node = events.pop()
      tail = node.tail
      args = if node.event  then [node.event].concat(rest)  else rest
      while (node = node.next) != tail
        node.callback.apply( node.context || this, args )
    this
