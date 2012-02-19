require 'spec_helper'
require 'chuchugo/server'

include ChuChuGo

describe Server do
  include Rack::Test::Methods
  def app()   @app ||= Server.new(nil, '/db', ChuChuGo.database)  end

  before do
    @app = nil ; app
    header 'ACCEPT', 'application/json'
    @coll = app.db['test']
    @url = "#{app.path}/#{@coll.name}"
  end

  it "#find" do
    now = Time.at(42)
    3.times { @coll.insert( now: now ) }

    json = [{now: now}, {}].to_ejson
    post "#{@url}/find", json, 'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    resp = ExtJSON.parse(last_response.body)

    resp.size == 3
    resp.each { |doc| doc[:now].should == now }
  end
end
