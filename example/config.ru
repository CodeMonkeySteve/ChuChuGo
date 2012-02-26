require 'bundler'
env = ENV['RACK_ENV'].to_sym || :development

require 'bundler'
Bundler.setup
Bundler.require

$: << File.dirname(__FILE__)+'/../lib'

require 'chuchugo'
use ChuChuGo::Websocket::Server, Mongo::Connection.from_uri('mongodb://localhost').db('chuchugo-dev')
Faye::WebSocket.load_adapter('thin')

map '/assets' do
  require 'sprockets'
  environment = Sprockets::Environment.new
  environment.append_path 'assets/javascripts'
  environment.append_path 'assets/stylesheets'
  environment.append_path '../assets/javascripts'
  run environment
end

map '/' do
  run Rack::File.new('index.html')
end
