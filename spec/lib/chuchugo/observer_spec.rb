require 'spec_helper'
require 'chuchugo/observer'

include ChuChuGo

describe Observer do
  before do
    mock(client = Object.new)
    @observer = Observer.new( client, ChuChuGo.database['things'], {} )
  end

  it "#fetch" do
    @observer.fetch
  end
end