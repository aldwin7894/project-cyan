# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rack-brotli` gem.
# Please instead update this file by running `bin/tapioca gem rack-brotli`.

# source://rack-brotli//lib/rack/brotli/version.rb#1
module Rack
  class << self
    # source://rack/2.2.8.1/lib/rack/version.rb#26
    def release; end

    # source://rack/2.2.8.1/lib/rack/version.rb#19
    def version; end
  end
end

# source://rack-brotli//lib/rack/brotli/deflater.rb#4
module Rack::Brotli
  class << self
    # source://rack-brotli//lib/rack/brotli.rb#10
    def new(app, options = T.unsafe(nil)); end

    # source://rack-brotli//lib/rack/brotli.rb#6
    def release; end
  end
end

# This middleware enables compression of http responses.
#
# Currently supported compression algorithms:
#
#   * br
#
# The middleware automatically detects when compression is supported
# and allowed. For example no transformation is made when a cache
# directive of 'no-transform' is present, or when the response status
# code is one that doesn't allow an entity body.
#
# source://rack-brotli//lib/rack/brotli/deflater.rb#15
class Rack::Brotli::Deflater
  # Creates Rack::Brotli middleware.
  #
  # [app] rack app instance
  # [options] hash of deflater options, i.e.
  #           'if' - a lambda enabling / disabling deflation based on returned boolean value
  #                  e.g use Rack::Brotli, :if => lambda { |env, status, headers, body| body.map(&:bytesize).reduce(0, :+) > 512 }
  #           'include' - a list of content types that should be compressed
  #           'deflater' - Brotli compression options
  #
  # @return [Deflater] a new instance of Deflater
  #
  # source://rack-brotli//lib/rack/brotli/deflater.rb#25
  def initialize(app, options = T.unsafe(nil)); end

  # source://rack-brotli//lib/rack/brotli/deflater.rb#33
  def call(env); end

  private

  # @return [Boolean]
  #
  # source://rack-brotli//lib/rack/brotli/deflater.rb#93
  def should_deflate?(env, status, headers, body); end
end

# source://rack-brotli//lib/rack/brotli/deflater.rb#66
class Rack::Brotli::Deflater::BrotliStream
  include ::Rack::Utils

  # @return [BrotliStream] a new instance of BrotliStream
  #
  # source://rack-brotli//lib/rack/brotli/deflater.rb#69
  def initialize(body, options); end

  # source://rack-brotli//lib/rack/brotli/deflater.rb#86
  def close; end

  # source://rack-brotli//lib/rack/brotli/deflater.rb#74
  def each(&block); end
end

# source://rack-brotli//lib/rack/brotli/version.rb#3
class Rack::Brotli::Version
  class << self
    # source://rack-brotli//lib/rack/brotli/version.rb#4
    def to_s; end
  end
end