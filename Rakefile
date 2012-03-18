require 'bundler'
Bundler.setup
Bundler.require #:default, :development, :test

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end

desc 'Build rubygem'
task 'build' do
  require 'sprockets'

  # force asset rebuild
  target = 'vendor/assets/javascripts'
  path = 'chuchugo.js'
  env = ::Sprockets::Environment.new
  env.append_path 'assets/javascripts'
  env.each_logical_path do |logical_path|
    next unless File.fnmatch(path, logical_path)
    if asset = env.find_asset(logical_path)
      filename = File.join( target, File.basename(logical_path) )
      asset.write_to(filename)
    end
  end

  `gem build chuchugo.gemspec`
end