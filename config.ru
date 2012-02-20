require 'bundler'
env = ENV['RACK_ENV'].to_sym || :development

require 'bundler'
Bundler.setup
Bundler.require

$: << File.dirname(__FILE__)+'/lib'

map '/assets' do
  require 'sprockets'
  environment = Sprockets::Environment.new
  environment.append_path 'assets/javascripts'
  environment.append_path 'assets/stylesheets'
  run environment
end

map '/db' do
  use Rack::Reloader  # debug
  use Rack::FiberPool

  require 'chuchugo'
  db = Mongo::Connection.from_uri('mongodb://localhost').db('chuchugo-dev')
  run ChuChuGo::Server.new(db)
end

map '/' do
  run Rack::File.new('example/index.html')
end
