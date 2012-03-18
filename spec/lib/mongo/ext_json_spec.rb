require 'spec_helper'
require 'mongo/ext_json'

describe "BSON to/from Extended JSON" do
  describe "#as_ejson" do
    it "Object" do
      obj = Object.new
      obj.as_ejson.should == obj.as_json
    end

    it "Time" do
      time = Time.at(42)
      time.as_ejson.should == {'$date' => (time.to_f * 1000).to_i}
    end

    it "Regexp" do
      regexp = /foo/im
      regexp.as_ejson.should == {'$regex' => 'foo', '$options' => 'im'}
    end

    it "ObjectId" do
      id = BSON::ObjectId('4f3feebb49f63b5b60000001')
      id.as_ejson.should == {'$oid' => id.to_s}
    end

    it "BSON::DBRef" do
      ref = BSON::DBRef.new('stuff', BSON::ObjectId('4f3feebb49f63b5b60000002') )
      ref.as_ejson.should == {'$ns' => ref.namespace, '$id' => ref.object_id.to_s}
    end

    it "Array" do
      array = [42, Time.at(42), 689]
      array.as_ejson.should == [array[0], array[1].as_ejson, array[2]]
    end

    it "Hash" do
      hash = { foo: { bar: { baaz: Time.at(42) } } }
      hash.as_ejson.should == { foo: { bar: { baaz: hash[:foo][:bar][:baaz].as_ejson } } }
    end
  end

  describe ".from_ejson" do
    it "Object" do
      Object.from_ejson(42).should == 42
    end

    it "ObjectId" do
      ejson = {'$oid' => '4f3feebb49f63b5b60000001'}
      BSON::ObjectId.from_ejson(ejson).should == BSON::ObjectId('4f3feebb49f63b5b60000001')
    end

    it "Time" do
      ejson = {'$date' => 42000}
      Time.from_ejson(ejson).should == Time.at(42)
    end

    it "Regexp" do
      ejson = {'$regex' => 'foo', '$options' => 'im'}
      Regexp.from_ejson(ejson).should == /foo/im
    end

    it "BSON::DBRef" do
      ejson = {'$ns' => 'stuff', '$id' => '4f3feebb49f63b5b60000002'}
      BSON::DBRef.from_ejson(ejson).should == BSON::DBRef.new(ejson['$ns'], BSON::ObjectId(ejson['$id']) )
    end

    it "Array" do
      ejson = [42, Time.at(42).as_ejson, 689]
      Array.from_ejson(ejson).should == [42, Time.at(42), 689]
    end

    it "Hash" do
      ejson = { foo: { bar: { baaz: Time.at(42).as_ejson } } }
      Hash.from_ejson(ejson).should == { foo: { bar: { baaz: Time.at(42) } } }.as_json
    end
  end
end
