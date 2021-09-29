require "sqlite3"
require "uuid"
require "uuid/json"

class SQLite3::Statement
  private def bind_arg(index, value : UUID)
    bind_arg(index, value.bytes.to_slice.dup)
  end
end

class SQLite3::ResultSet
  def read(t : UUID.class) : UUID
    UUID.new(read(Bytes))
  end

  def read(t : UUID?.class) : UUID?
    if bytes = read(Bytes)
      UUID.new(bytes)
    end
  end
end
