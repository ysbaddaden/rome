require "pg"
require "uuid"
require "uuid/json"

module PG
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
      encode val.to_slice.clone
    end
  end
end
