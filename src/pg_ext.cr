require "pg"
require "uuid"
require "uuid/json"

module PG
  module Decoders
    struct UUIDDecoder
      include Decoder

      def_oids [
        2950, # uuid
      ]

      def decode(io, bytesize, oid)
        bytes = uninitialized UInt8[16]
        io.read(bytes.to_slice)
        UUID.new(bytes)
      end

      def type
        UUID
      end
    end

    # replaces the original UUID decoder that returns a string:
    register_decoder UUIDDecoder.new
  end
end

struct PQ::Param
  def self.encode(val : UUID)
    encode Bytes.new(val.to_unsafe, 16).dup
  end
end
