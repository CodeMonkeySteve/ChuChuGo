source :rubygems

gem 'activesupport', require: %w(active_support active_support/core_ext)
gem 'i18n'
gem 'json'
gem 'rack'
gem 'thin'
gem 'rack-fiber_pool', require: 'rack/fiber_pool'

gem 'mongo'
gem 'bson_ext'

gem 'sprockets'
gem 'coffee-script'

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'jasmine'

  gem 'linecache19', git: 'git://github.com/mark-moseley/linecache'
  gem 'ruby-debug-base19x',  '~> 0.11.30.pre4'
  gem 'ruby-debug19', require: 'ruby-debug'
end

group :development_linux do
  gem 'rb-inotify', git: 'git://github.com/hron/rb-inotify.git', branch: 'fix-guard-crash-when-file-is-deleted-very-fast'
  gem 'libnotify'
end
group :development_darwin do
  gem 'rb-fsevent'
  gem 'growl'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'rack-test', require: 'rack/test'
  gem 'rr'
  gem 'rspec'
  gem 'timecop'
  gem 'webmock'
end
