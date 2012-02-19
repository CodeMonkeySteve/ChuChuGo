require 'bundler'
Bundler.require :default, :test, :development, "development_#{/darwin|linux|win32/.match(RUBY_PLATFORM)[0]}"

require 'rspec'
require 'rack_ext'

module ChuChuGo
  def self.database
    unless @database
      logger = ActiveSupport::BufferedLogger.new( $stdout, ActiveSupport::BufferedLogger::Severity::DEBUG )
      @database = Mongo::Connection.from_uri('mongodb://localhost', logger: logger).db('chuchugo-test')
    end
    @database
  end
end

RSpec.configure do |config|
  config.mock_with :rr
  def config.fixture_path()  @fixture_path ||= File.dirname(__FILE__)+'/fixtures'  end

  Dir[File.dirname(__FILE__)+"/support/**/*.rb"].each { |f| require f }
end


