require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "natwest"
    gem.summary = %Q{Rudimentary API for Natwest Online Banking}
    gem.description = "View balance and recent transactions of " +
                      "a Natwest account from the command line."
    gem.email = "runrun@runpaint.org"
    gem.homepage = "http://github.com/runpaint/natwest"
    gem.authors = ["Run Paint Run Run"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    gem.add_dependency "highline", ">= 0"
    gem.extra_rdoc_files = []
    gem.rdoc_options = []
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
Rspec::Core::RakeTask.new do |spec|
  spec.ruby_opts = '-r./spec/spec_helper'
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
