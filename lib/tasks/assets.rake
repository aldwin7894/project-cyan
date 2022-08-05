# frozen_string_literal: true

# Removing the node_modules folder after compilation but right before the slug is generated.
# Adapted from https://github.com/heroku/heroku-buildpack-ruby/issues/792

namespace :assets do
  desc "Vite build"
  task :precompile do
    puts "Execute vite build"
    Rake::Task["vite:clobber"].invoke
    Rake::Task["vite:build"].invoke

    puts "Clear cache"
    Rake::Task["tmp:clear"].invoke
    Rake::Task["tmp:cache:clear"].invoke
  end

  desc "Remove 'node_modules' folder"
  task :clean do
    puts "Removing node_modules folder"
    FileUtils.remove_dir("node_modules", true)
  end
end
