# frozen_string_literal: true

# Removing the node_modules folder after compilation but right before the slug is generated.
# Adapted from https://github.com/heroku/heroku-buildpack-ruby/issues/792

namespace :assets do
  desc "Vite build"
  task :precompile do
    print "Execute vite build"
    Rake::Task["vite:build"].invoke
  end

  desc "Clean old build and remove 'node_modules' folder"
  task :clean do
    print "Cleaning old vite build"
    Rake::Task["vite:clean"].invoke
    print "Removing node_modules folder"
    FileUtils.remove_dir("node_modules", true)
  end
end
