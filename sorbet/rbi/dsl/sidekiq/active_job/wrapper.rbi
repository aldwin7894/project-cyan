# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Sidekiq::ActiveJob::Wrapper`.
# Please instead update this file by running `bin/tapioca dsl Sidekiq::ActiveJob::Wrapper`.


class Sidekiq::ActiveJob::Wrapper
  class << self
    sig { params(job_data: T.untyped).returns(String) }
    def perform_async(job_data); end

    sig { params(interval: T.any(DateTime, Time), job_data: T.untyped).returns(String) }
    def perform_at(interval, job_data); end

    sig { params(interval: Numeric, job_data: T.untyped).returns(String) }
    def perform_in(interval, job_data); end
  end
end