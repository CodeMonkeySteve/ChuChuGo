require 'pathname'
require 'webmock/rspec'

module WebMock
  Allow = %w().freeze
end

RSpec.configure do |config|
  dir = config.fixture_path + 'webmock'
  stubs = {}
  Dir["#{dir}/**/*"].each  do |path|
    next  if File.directory? path
    uri = path.dup
    uri.slice!( "#{dir}/" )
    uri = File.dirname(uri)+'/'  if File.basename(uri) == '_directory'
    stubs["http://#{uri}"] = path
#puts "http://#{uri}, #{path}"
  end

  config.around(:each) do |example|
    stubs.each { |uri, path|  WebMock::API.stub_request(:get, uri).to_return( File.new(path) )  }
    WebMock.disable_net_connect!(allow_localhost: true, allow: WebMock::Allow)
    example.call
    WebMock.allow_net_connect!
  end
end

class WebMock::NetConnectNotAllowedError
  def stubbing_instructions(sig)
    text = "\n\n"
    text << "You can stub this request with the following command:\n\n"
    if sig.method == :get
      dir = RSpec.configuration.fixture_path + 'webmock'  + sig.uri.host
      dir += ":#{sig.uri.port}"  if sig.uri.normalized_port
      path = dir.to_s + sig.uri.omit(:scheme,:userinfo,:host,:port)
      text << "  mkdir -p '#{File.dirname(path)}' && curl -i -o '#{path}' '#{sig.uri}'"
    else
      text << WebMock::StubRequestSnippet.new(request_signature).to_s
    end
    text << "\n\n" + "="*60
    text
  end
end
