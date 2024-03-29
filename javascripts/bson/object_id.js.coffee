class BSON.ObjectId
  BSON.Conversions.unshift(this)  # most common, should go first

  @machineID = (
    if window.localStorage? && (id = window.localStorage.getItem('BSON.MachineID'))?
      Number(id)
    else
      id = Math.floor(Math.random() * 16777216)
      window.localStorage.setItem('BSON.MachineID', id)  if window.localStorage?
  )
  @processID = (
    if window.sessionStorage? && (id = window.sessionStorage.getItem('BSON.ProcessID'))?
      Number(id)
    else
      id = Math.floor(Math.random() * 32767)
      window.sessionStorage.setItem('BSON.ProcessID', id)  if window.sessionStorage?
      id
  )
  @increment = 0

  constructor: (args...) ->
    if args.length == 1
      arg = args[0]
      if _.isObject(arg) && arg.time? && arg.machine? && arg.pid && arg.inc
        @time = arg.time
        @machine = arg.machine
        @pid = arg.pid
        @inc = arg.inc

      else if _.isString(arg) && (arg.length == 24)
        @time    = Number('0x' + arg.substr( 0, 8))
        @machine = Number('0x' + arg.substr( 8, 6))
        @pid     = Number('0x' + arg.substr(14, 4))
        @inc     = Number('0x' + arg.substr(18, 6))

    else if args.length == 4
      [@time, @machine, @pid, @inc] = args

    else if args.length
      throw("Bad agruments: " + args)

    else
      @generate()
    return this

  generate: ->
    @time = Math.floor(new Date().valueOf() / 1000)
    @machine = ObjectId.machineID
    @pid = ObjectId.processID
    @inc = ObjectId.increment = (ObjectId.increment + 1) & 0xff
    this

  createdAt: ->
    new Date( @time * 1000 )

  toString: ->
    time = @time.toString(16)
    machine = @machine.toString(16)
    pid = @pid.toString(16)
    inc = @inc.toString(16)
    '00000000'.substr(0, 6 - time.length) + time +
      '000000'.substr(0, 6 - machine.length) + machine +
      '0000'.substr(0, 4 - pid.length) + pid +
      '000000'.substr(0, 6 - inc.length) + inc

  @toEJSON: (id) ->
    $oid: id.toString()
  @fromEJSON: (ejson) ->
    _.isEqual( _.keys(ejson), ['$oid'] ) && new ObjectId(ejson['$oid'])
