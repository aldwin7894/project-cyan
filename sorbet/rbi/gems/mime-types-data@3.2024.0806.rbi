# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `mime-types-data` gem.
# Please instead update this file by running `bin/tapioca gem mime-types-data`.


# source://mime-types-data//lib/mime/types/data.rb#3
module MIME; end

# source://mime-types-data//lib/mime/types/data.rb#4
class MIME::Types
  extend ::Enumerable

  # source://mime-types/3.5.2/lib/mime/types.rb#75
  def initialize; end

  # source://mime-types/3.5.2/lib/mime/types.rb#125
  def [](type_id, complete: T.unsafe(nil), registered: T.unsafe(nil)); end

  # source://mime-types/3.5.2/lib/mime/types.rb#167
  def add(*types); end

  # source://mime-types/3.5.2/lib/mime/types.rb#188
  def add_type(type, quiet = T.unsafe(nil)); end

  # source://mime-types/3.5.2/lib/mime/types.rb#81
  def count; end

  # source://mime-types/3.5.2/lib/mime/types.rb#90
  def each; end

  # source://mime-types/3.5.2/lib/mime/types.rb#85
  def inspect; end

  # source://mime-types/3.5.2/lib/mime/types.rb#153
  def of(filename); end

  # source://mime-types/3.5.2/lib/mime/types.rb#153
  def type_for(filename); end

  private

  # source://mime-types/3.5.2/lib/mime/types.rb#201
  def add_type_variant!(mime_type); end

  # source://mime-types/3.5.2/lib/mime/types.rb#211
  def index_extensions!(mime_type); end

  # source://mime-types/3.5.2/lib/mime/types.rb#221
  def match(pattern); end

  # source://mime-types/3.5.2/lib/mime/types.rb#215
  def prune_matches(matches, complete, registered); end

  # source://mime-types/3.5.2/lib/mime/types.rb#205
  def reindex_extensions!(mime_type); end

  class << self
    # source://mime-types/3.5.2/lib/mime/types/registry.rb#14
    def [](type_id, complete: T.unsafe(nil), registered: T.unsafe(nil)); end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#39
    def add(*types); end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#19
    def count; end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#24
    def each; end

    # source://mime-types/3.5.2/lib/mime/types/logger.rb#12
    def logger; end

    # source://mime-types/3.5.2/lib/mime/types/logger.rb#12
    def logger=(_arg0); end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#7
    def new(*_arg0); end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#33
    def of(filename); end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#33
    def type_for(filename); end

    private

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#75
    def __instances__; end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#55
    def __types__; end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#45
    def lazy_load?; end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#65
    def load_default_mime_types(mode = T.unsafe(nil)); end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#60
    def load_mode; end

    # source://mime-types/3.5.2/lib/mime/types/registry.rb#79
    def reindex_extensions(type); end
  end
end

# source://mime-types-data//lib/mime/types/data.rb#5
module MIME::Types::Data; end

# The path that will be used for loading the MIME::Types data. The
# default location is __FILE__/../../../../data, which is where the data
# lives in the gem installation of the mime-types-data library.
#
# The MIME::Types::Loader will load all JSON or columnar files contained
# in this path.
#
# System maintainer note: this is the constant to change when packaging
# mime-types for your system. It is recommended that the path be
# something like /usr/share/ruby/mime-types/.
#
# source://mime-types-data//lib/mime/types/data.rb#18
MIME::Types::Data::PATH = T.let(T.unsafe(nil), String)

# source://mime-types-data//lib/mime/types/data.rb#6
MIME::Types::Data::VERSION = T.let(T.unsafe(nil), String)