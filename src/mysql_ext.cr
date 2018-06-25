require "mysql"
require "uuid"

abstract struct MySql::Type
  def self.type_for(t : ::UUID.class)
    MySql::Type::UUID
  end

  decl_type UUID, 0xfeu8, ::UUID do
    def self.write(packet, v : ::UUID)
      packet.write_lenenc_string v.to_s
    end

    def self.read(packet)
      packet.read_lenenc_string
    end

    def self.parse(str : ::String)
      ::UUID.new(str)
    end
  end
end
