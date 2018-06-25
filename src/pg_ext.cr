require "pg"
require "uuid"

module PG
  # alias PGValue = String | Nil | Bool | Int32 | Float32 | Float64 | Time | JSON::Any | PG::Numeric | UUID

  module Decoders
    struct UuidDecoder
      def decode(io, bytesize)
        bytes = uninitialized UInt8[16]
        io.read(bytes.to_slice)
        UUID.new(bytes)
      end
    end
  end
end

module PQ
  struct Param
    def self.encode(val : UUID)
      encode Slice.new(16) { |i| val.to_unsafe[i] }
    end
  end
end
