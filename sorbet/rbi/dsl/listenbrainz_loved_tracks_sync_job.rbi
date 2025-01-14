# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `ListenbrainzLovedTracksSyncJob`.
# Please instead update this file by running `bin/tapioca dsl ListenbrainzLovedTracksSyncJob`.


class ListenbrainzLovedTracksSyncJob
  class << self
    sig { params(args: T.untyped).returns(String) }
    def perform_async(*args); end

    sig { params(interval: T.any(DateTime, Time), args: T.untyped).returns(String) }
    def perform_at(interval, *args); end

    sig { params(interval: Numeric, args: T.untyped).returns(String) }
    def perform_in(interval, *args); end
  end
end
