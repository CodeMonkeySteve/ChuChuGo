require 'mongo'

module Mongo

class OpLog
  class Observer
    attr_reader :collection

    def initialize( collection )
      @collection = collection
    end

    def on_insert( doc ) end
    def on_update( id, mod ) end
    def on_remove( id ) end
    def on_command( cmd ) end
  end

  def initialize(conn, opts = {})
    @conn, @opts = conn, opts
    @last_ts = @opts.delete(:ts) || BSON::Timestamp.now
    @interval = @opts.delete(:interval) || 1.0
    @observers = {}
  end

  def start(interval = nil)
    @interval = interval  if interval
    @timer && @timer.cancel
    @timer = EM.add_periodic_timer( @interval, &self.method(:poll) )
    self
  end

  def observe( observer, &blk )
    observer = Observer.new(observer)  unless observer.is_a?(Observer)
    observer.instance_eval(&blk)  if blk

    name = observer.collection.db.name + '.' + observer.collection.name
    if (new_coll = !@observers[name])
      @observers[name] = []
    end
    @observers[name] << observer

    @cursor = nil  if new_coll  # recreate cursor (lazily) if collections change
    observer
  end

  def ignore( observer )
    name = observer.collection.db.name + '.' + observer.collection.name
    return unless obs = @observers[name]
    obs.delete(observer)
    if obs.empty?
      @cursor = nil  # recreate cursor (lazily) if collections change
      @observers.delete(name)
    end
    observer
  end

  def poll
    while entry = cursor.next
      ts = entry['ts']
      next if @last_ts && (ts <= @last_ts)
      @last_ts = ts
      next if %w(n db).include?(entry['op'])  # no-op, database declaration
      next unless (observers = @observers[entry['ns']]).present?

      Log.tagged('OpLog') {  Log.debug entry.inspect  }
      case entry['op']
        when 'i'
          observers.each do |o|
            o.on_insert( entry['o'] )
          end

        when 'u'
          observers.each do |o|
            raise "Unknown update spec: #{entry['o2']}"  unless entry['o2'].keys == %w(_id)
            o.on_update( entry['o2']['_id'], entry['o'] )
          end

        when 'd'
          observers.each do |o|
            raise "Unknown delete spec: #{entry['o']}"  unless entry['o'].keys == %w(_id)
            o.on_remove( entry['o']['_id'] )
          end

        when 'c'
          observers.each { |o|  o.on_command(entry['o']) }

        else
          raise "Unknown op: #{entry['op']}"
      end
    end
  end

protected

  def cursor
    unless @cursor
      if @observers.empty?
        (@cursor = {}).define_singleton_method(:next) { nil }
      else
        opts = @opts.merge( tailable: true, order: [['$natural', 1]], selector: { ns: {'$in' => @observers.keys} } )
        @cursor = Mongo::Cursor.new( @conn['local']['oplog.$main'], opts )
      end
    end
    @cursor
  end
end

end

module BSON
  class Timestamp
    @@secs = nil
    @@count = 0

    def self.now
      inc = nil
      secs = Time.now.to_i
      if secs == @@secs
        inc = (@@count += 1)
      else
        @@secs = secs
        inc = @@count = 0
      end
      self.new( secs, inc )
    end

    def <=>( that )
      res = (self.seconds <=> that.seconds)
      res.nonzero? ? res : (self.increment <=> that.increment)
    end

    def <=( that )  self.<=>(that) <= 0  end
  end
end
