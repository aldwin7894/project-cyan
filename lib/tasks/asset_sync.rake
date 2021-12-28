# We need this rake task to make running of assets:precompile correct, 
# so that webpacker assets are included in the files to be pushed to S3,
# otherwise asset_sync runs before webpacker:compile does and we will miss their assets.
if defined?(AssetSync)
  Rake::Task['webpacker:compile'].enhance do
    Rake::Task["assets:sync"].invoke
  end
end
