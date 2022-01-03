# frozen_string_literal: true

Aws.config.update({
  credentials: Aws::Credentials.new(
    Rails.application.credentials.aws[:access_key_id],
    Rails.application.credentials.aws[:secret_access_key]
  ),
  region: "us-west-2"
})

S3_BUCKET        = Aws::S3::Resource.new.bucket("aldwin7894-web")
# Define the environment folder where S3 will store files.
S3_BUCKET_ENV    = ENV.fetch("S3_BUCKET_ENV") { "development" }
# Define the default image from S3.
S3_DEFAULT_IMAGE = S3_BUCKET.object("web/#{S3_BUCKET_ENV}/assets/default-slider-74e68e393f6bd0ae99a0629355cad26bda0913d2b658bf0f684ad672d438d44d.jpg")
