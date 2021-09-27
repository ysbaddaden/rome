require "./adapter"

module Rome
  struct Adapter::SQLite3 < Adapter
    def self.quote(name : Symbol | String, io : IO)
      io << '`'
      name.to_s(io)
      io << '`'
    end
  end

  register_adapter("sqlite3", Adapter::SQLite3)
end
