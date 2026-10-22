# Both bundling gems default to `npm install`. Share one immutable install instead.
namespace :npm do
  task :install do
    sh 'npm ci'
  end
end

%w[javascript:install css:install].each do |name|
  Rake::Task[name].clear.enhance(['npm:install'])
end
