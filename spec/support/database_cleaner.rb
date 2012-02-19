class ::Mongoid
  def self.database()  ChuChuGo.database  end
end

class RSpec::Core::ExampleGroup
  RSpec.configure do |config|
    config.before(:suite) do
      DatabaseCleaner.orm = :mongoid
      DatabaseCleaner.strategy = :truncation
    end
    config.before(:all) do
      DatabaseCleaner.clean
    end
  end
end
