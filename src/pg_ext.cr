require "pg"
require "uuid"
require "uuid/json"

struct PG::Decoders::UuidDecoder
  def decode(io, bytesize)
    bytes = uninitialized UInt8[16]
    io.read(bytes.to_slice)
    UUID.new(bytes)
  end
end

struct PQ::Param
  def self.encode(val : UUID)
    encode val.to_slice.clone
  end
end
