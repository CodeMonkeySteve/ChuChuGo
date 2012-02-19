require 'rack_ext'
require 'chuchugo/conversions'

module ChuChuGo

class Server
  attr_reader :app, :path, :db, :opts

  def initialize( app, path, db, opts = {} )
    @app, @path, @db, @opts = app, path, db, opts
    @path = "/#{@path}"  unless @path[0] == '/'
  end

  def call( env )
    @env, req = env, Rack::Request.new(env)
    return [400, {}, ["Bad Request"]] unless req.accept.include?('application/json')

    if %r(#{@path}/(\w+)/(find|insert|update|remove)/?$) =~ req.path_info
      coll_name, op = $1, $2
      unless (req.content_type == 'application/json') && (args = ExtJSON.parse(req.body.read))
        return [400, {}, ["Bad Request"]]
      end

      coll = db[coll_name]
      res = self.send( op.to_sym, coll, *args )
      [200, {'CONTENT_TYPE' => 'application/json'}, [res.to_a.to_ejson]]
    else
      @app ? @app.call(env) : [404, {}, []]
    end
  end

  def find( coll, query, opts = {} )
    coll.find( query, opts )
  end

  def insert()
  end

  def update()
  end

  def remove()
  end
end

end