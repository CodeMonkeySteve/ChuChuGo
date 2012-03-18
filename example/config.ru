require 'bundler'
Bundler.setup
env = ENV['RACK_ENV'].to_sym || :development
Bundler.require env, :example
Bundler.require( 'development_' + /darwin|linux|win32/.match(RUBY_PLATFORM)[0] )  if env == 'development'
$: << File.dirname(__FILE__)+'/../lib'

#require 'rack/fiber_pool'
#use Rack::FiberPool

require 'chuchugo'
::Log = ActiveSupport::TaggedLogging.new( Logger.new($stdout) )

db_log = Logger.new($stdout).tap { |l|  l.level = Logger::INFO }
db = Mongo::Connection.from_uri('mongodb://localhost', logger: db_log).db('chuchugo-dev')
use ChuChuGo::Websocket::Server, db, interval: 0.20

map '/assets' do
  require 'sprockets'
  env = Sprockets::Environment.new
  env.append_path '.'
  env.append_path '../javascripts'
  run env
end

map '/' do
  run Rack::File.new('example.html')
end
