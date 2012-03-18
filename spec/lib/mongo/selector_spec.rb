require 'spec_helper'
require 'mongo/selector'

include Mongo

describe Selector do
  def pr( spec = nil )
    @pr = Selector.new(spec)  if spec
    @pr
  end

  it "sym => scalar" do
    pr(x: 42).should =~ {x: 42}
    pr.should_not =~ {x: 69}
  end
  it "path => scalar" do
    pr('x.y.z' => 42).should =~ {x: {y: {z: 42}}}
    pr.should_not =~ {x: {y: {z: 69}}}
    pr.should_not =~ {x: 42}
  end
  it "sym => array" do
    pr(x: [42,69]).should =~ {x: [42, 69]}
    pr.should_not =~ {x: 42}
    pr.should_not =~ {x: [69, 42]}
  end
  it "multiple" do
    pr(x: 42, y: 69).should =~ {x: 42, y: 69}
  end

  it ">" do
    pr(x: {:$gt => 42}).should =~ {x: 43}
    pr.should_not =~ {x: 41}
  end
  it "<" do
    pr(x: {:$lt => 42}).should =~ {x: 41}
    pr.should_not =~ {x: 43}
  end
  it ">=" do
    pr(x: {:$gte => 42}).should =~ {x: 42}
    pr.should_not =~ {x: 41}
  end
  it "<=" do
    pr(x: {:$lte => 42}).should =~ {x: 42}
    pr.should_not =~ {x: 43}
  end
  it "!=" do
    pr(x: {:$ne => 42}).should =~ {x: 43}
    pr.should_not =~ {x: 42}
  end

  it "exists (true)" do
    pr(x: {:$exists => true}).should =~ {x: 42}
    pr.should_not =~ {y: 42}
  end
  it "exists (false)" do
    pr(x: {:$exists => false}).should =~ {y: 42}
    pr.should_not =~ {x: 42}
  end

  it "$in" do
    pr(x: {:$in => [42, 69]}).should =~ {x: 42}
    pr.should =~ {x: [69, 123]}
    pr.should =~ {x: 69}
    pr.should_not =~ {x: 12}
  end
  it "$nin" do
    pr(x: {:$nin => [42, 69]}).should =~ {x: 123}
    pr.should =~ {x: [50, 70]}
    pr.should_not  =~ {x: 42}
  end
  it "$all" do
    pr(x: {:$all => [42, 69]}).should =~ {x: [42, 69]}
    pr.should =~ {x: [69, 42]}
    pr.should =~ {x: [69, 42, 123]}
    pr.should_not =~ {x: [42]}
  end

  it "$or" do
    pr(:$or => [{x: 42}, {y: 69}]).should =~ {x: 42}
    pr.should =~ {y: 69}
    pr.should_not =~ {x: 69}
  end
  it "$nor" do
    pr(:$nor => [{x: 42}, {y: 69}]).should =~ {y: 42}
    pr.should_not =~ {x: 42}
  end

  it "$size" do
    pr(x: {:$size => 2}).should =~ {x: [42, 69]}
    pr.should_not =~ {x: [42]}
  end
  it "$elemMatch" do
    pr(x: {:$elemMatch => {y: 42}}).should =~ {x: [{z: 123}, {y: 42}]}
    pr.should_not =~ {x: [{z: 123}, {w: 42}]}
  end
  it "$not" do
    pr(:$not => {x: 42}).should =~ {x: 69}
    pr.should =~ {y: 42}
    pr.should_not =~ {x: 42}
  end
end
