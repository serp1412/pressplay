require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_tests.rb']
end

desc "Run tests"
task :default => :test