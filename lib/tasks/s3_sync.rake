# frozen_string_literal: true

require "s3_asset_deploy"

class PublicLocalAssetCollector < S3AssetDeploy::LocalAssetCollector
  def assets
    # include public  
    Dir[File.join(::Rails.public_path, "/*.*")].map do |path|
      S3AssetDeploy::LocalAsset.new(path)
    end
  end
end

namespace :assets do
  desc "Sync static assets to S3"
  task :s3_sync do
    manager = S3AssetDeploy::Manager.new(
      "aldwin7894-web",
      s3_client_options: {
        region: Rails.application.credentials.aws[:region],
        access_key_id: Rails.application.credentials.aws[:access_key_id],
        secret_access_key: Rails.application.credentials.aws[:secret_access_key]
      },
      local_asset_collector: PublicLocalAssetCollector.new
    )
    manager.deploy do
      # Perform deploy to web instances in this block.
      # How you do this will depend on where you are hosting your application and what tools you use to deploy.
    end
  end
end
