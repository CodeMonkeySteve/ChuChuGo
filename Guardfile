$: << File.dirname(__FILE__)+'/lib'

group 'specs' do
  guard 'rspec', all_after_pass: false, cli: '--color --format nested -d' do  # --fail-fast --drb
    watch(%r{(^|/)\.'}) {}  # ignore dot files
    watch('spec/spec_helper.rb')        { "spec" }
    watch(%r{^spec/(.+)_spec\.rb})      { |m| m[0] }
    watch(%r{^spec/factories/(.+)\.rb}) { "spec" }
    watch(%r{^lib/(.+)\.rb})            { |m| "spec/lib/#{m[1]}_spec.rb" }
  end
end

group 'assets' do
  env = guard 'sprockets', output: 'tmp/compiled-assets', assets: ['example.js', 'support/test.js'] do
    watch %r{^assets.*/[^\.][^/]+\.(js|css|sass)}
    watch %r{^spec/javascripts.*/[^\.][^/]+\.js}
  end.env

  env.append_path 'assets/javascripts'
  env.append_path 'assets/stylesheets'
  env.append_path 'spec/javascripts'
end

