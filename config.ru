require 'bundler'

env = ENV['RACK_ENV'].to_sym
Bundler.setup :default, env
Bundler.setup "development_#{/darwin|linux|win32/.match(RUBY_PLATFORM)[0]}"  if env == :development

require File.dirname(__FILE__)+'/lib/chuchugo'

db = Mongo::Connection.from_uri('mongodb://localhost').db('chuchugo-dev')
use ChuChuGo::Server, db, path: '/db'

run proc { [404, {}, [] ] }