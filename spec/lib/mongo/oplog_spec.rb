require 'spec_helper'
require 'mongo/oplog'

include Mongo

describe OpLog do
  before do
    @oplog = OpLog.new(ChuChuGo.database.connection)
  end

  it "#poll" do
    @oplog.poll

    coll = ChuChuGo.database['things']
    @oplog.observe coll do
#       def on_insert( doc )
#         puts "insert:"
#         pp doc
#         puts
#       end
#       def on_update( id, mod )
#         puts "update:"
#         pp id, mod
#         puts
#       end
#       def on_remove( id )
#         puts "remove:"
#         pp id
#         puts
#       end
#       def on_command( cmd )
#         puts "command:"
#         pp cmd
#         puts
#       end
    end

    coll.save( owner: 'tester', x: 42 )
    #coll.save( owner: 'tester', x: 69 )
    #coll.update( {owner: {'$in' => %w(tester foo)}, x: {'$lt' => 60}}, {'$set' => {foo: 42}}, multi: true )
    #coll.remove( owner: 'tester' )

    @oplog.poll
  end
end
