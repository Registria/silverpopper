# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "silverpopper"
  gem.homepage = "http://github.com/where/silverpopper"
  gem.license = "MIT"
  gem.summary = %Q{a simple interface to the Silverpop XMLAPI and Transact API}
  gem.description = %Q{handle authentication, and wrap api calls in standard ruby code to
                       so you don't have to think about xml when communicating with silverpop}
  gem.email = "whereweb@where.com"
  gem.authors = ["WHERE, Inc"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test
