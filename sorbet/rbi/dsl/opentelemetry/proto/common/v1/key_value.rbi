# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Opentelemetry::Proto::Common::V1::KeyValue`.
# Please instead update this file by running `bin/tapioca dsl Opentelemetry::Proto::Common::V1::KeyValue`.

class Opentelemetry::Proto::Common::V1::KeyValue
  sig { params(key: T.nilable(String), value: T.nilable(Opentelemetry::Proto::Common::V1::AnyValue)).void }
  def initialize(key: nil, value: nil); end

  sig { void }
  def clear_key; end

  sig { void }
  def clear_value; end

  sig { returns(String) }
  def key; end

  sig { params(value: String).void }
  def key=(value); end

  sig { returns(T.nilable(Opentelemetry::Proto::Common::V1::AnyValue)) }
  def value; end

  sig { params(value: T.nilable(Opentelemetry::Proto::Common::V1::AnyValue)).void }
  def value=(value); end
end