require 'bundler'
Bundler.require :default, :test, :development, "development_#{/darwin|linux|win32/.match(RUBY_PLATFORM)[0]}"

require 'rspec'
require 'rack_ext'

::Log = ActiveSupport::TaggedLogging.new( Logger.new( $stdout, Logger::DEBUG ) )

module ChuChuGo
  def self.database
    unless @database
      @database = Mongo::Connection.from_uri('mongodb://localhost', logger: Log).db('chuchugo-test')
    end
    @database
  end
end

RSpec.configure do |config|
  config.mock_with :rr
  def config.fixture_path()  @fixture_path ||= File.dirname(__FILE__)+'/fixtures'  end

  Dir[File.dirname(__FILE__)+"/support/**/*.rb"].each { |f| require f }
end


