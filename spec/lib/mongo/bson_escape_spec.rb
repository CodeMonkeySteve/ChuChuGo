require 'spec_helper'
require 'mongo/bson_escape'

describe BSON do
  it ".escape" do
    BSON.escape('$foo' => 42).should == {'_$foo' => 42}
    BSON.escape('foo.bar' => 77).should == {'foo\*bar' => 77}
  end
  it ".unescape" do
    BSON.unescape('_$foo' => 42).should == {'$foo' => 42}
    BSON.unescape('foo\*bar' => 77).should == {'foo.bar' => 77}
  end
end