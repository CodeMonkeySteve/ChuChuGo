Gem::Specification.new do |s|
  #s.rubygems_version = %q{1.7.2}
  s.specification_version = 3

  s.name = 'chuchugo'
  s.version = '0.0.1'
  s.date = %q{2012-03-11}

  s.description = "A combination of Rack middleware and Javascript ODM to allow for transparent, asynchronous, bi-direction replication with MongoDB."
  s.homepage = 'http://github.com/CodeMonkeySteve/ChuChuGo'
  s.summary = "MongoDB synchronization with the web browser"
  s.authors = ["Steve Sloan"]
  s.email = 'steve@finagle.org'

  s.require_paths = %w(lib)
  s.files = [
    'Gemfile',
    'Gemfile.lock',
    'MIT-LICENSE',
    'README.textile',
    'Rakefile',

    'lib/chuchugo.rb',
    'lib/rack_ext.rb',
    'lib/chuchugo/client.rb',
    'lib/chuchugo/live_query.rb',
    'lib/chuchugo/query.rb',
    'lib/chuchugo/rails.rb',
    'lib/chuchugo/rpc.rb',
    'lib/chuchugo/server.rb',
    'lib/mongo/bson_escape.rb',
    'lib/mongo/ext_json.rb',
    'lib/mongo/field_set.rb',
    'lib/mongo/oplog.rb',
    'lib/mongo/selector.rb',

    'assets/bson/bson.js.coffee',
    'assets/bson/object_id.js.coffee',
    'assets/chuchugo.js.coffee',
    'assets/chuchugo/collection.js.coffee',
    'assets/chuchugo/database.js.coffee',
    'assets/chuchugo/events.js.coffee',
    'assets/chuchugo/model.js.coffee',
    'assets/underscore_ext.js.coffee',

    'vendor/assets/javascripts/chuchugo.js',

    'spec/lib/mongo/bson_escape_spec.rb',
    'spec/lib/mongo/ext_json_spec.rb',
    'spec/lib/mongo/selector_spec.rb',

    'spec/javascripts/application_spec.js.coffee',
    'spec/javascripts/bson_spec.js.coffee',

    'spec/spec_helper.rb',
    'spec/javascripts/support/jasmine_config.rb',
    'spec/javascripts/support/jasmine_config.rb',
    'spec/javascripts/support/jasmine-jquery-1.2.0.js',
    'spec/javascripts/support/jasmine_runner.rb',
    'spec/javascripts/support/jasmine.yml',
    'spec/javascripts/support/test.js',
  ]
  s.test_files = [
    'spec/lib/mongo/bson_escape_spec.rb',
    'spec/lib/mongo/ext_json_spec.rb',
    'spec/lib/mongo/selector_spec.rb',

    'spec/javascripts/application_spec.js.coffee',
    'spec/javascripts/bson_spec.js.coffee',
    'spec/javascripts/support/jasmine_config.rb',
    'spec/javascripts/support/jasmine_config.rb',
    'spec/javascripts/support/jasmine-jquery-1.2.0.js',
    'spec/javascripts/support/jasmine_runner.rb',
    'spec/javascripts/support/jasmine.yml',
    'spec/javascripts/support/test.js',

    'spec/spec_helper.rb'
  ]

  s.add_runtime_dependency('activesupport', ['>= 0'])
  s.add_runtime_dependency('json', ['>= 0'])
  s.add_runtime_dependency('mongo', ['>= 0'])
  s.add_runtime_dependency('faye-websocket', ['>= 0'])
  s.add_runtime_dependency('rack', ['>= 0'])
  s.add_runtime_dependency('thin', ['>= 0'])

  s.add_development_dependency('rspec', ['>= 0'])
  s.add_development_dependency('sprockets', ['>= 0'])
  s.add_development_dependency('coffee-script', ['>= 0'])
  s.add_development_dependency('jasmine', ['>= 0'])
end

