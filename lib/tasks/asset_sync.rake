# frozen_string_literal: true

# We need this rake task to make running of assets:precompile correct,
# so that webpacker assets are included in the files to be pushed to S3,
if defined?(S3AssetDeploy)
  Rake::Task["webpacker:compile"].enhance do
    Rake::Task["assets:s3_sync"].invoke
  end
end
