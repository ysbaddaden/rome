require "mysql"
require "uuid"
require "uuid/json"

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
  end
end

class MySql::ResultSet
  def read(t : ::UUID.class)
    ::UUID.new(read(String))
  end

  def read(t : (::UUID | Nil).class)
    if v = read(String?)
      ::UUID.new(v)
    end
  end
end
