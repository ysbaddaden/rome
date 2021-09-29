require "./adapter"

module Rome
  struct Adapter::SQLite3 < Adapter
    def self.quote(name : Symbol | String, io : IO)
      io << '`'
      name.to_s(io)
      io << '`'
    end

    private def build_insert(attributes : Hash|NamedTuple, io, args)
      if attributes.empty?
        io << "INSERT INTO "
        quote(builder.table_name, io)
        io << " DEFAULT VALUES"
      else
        super
      end
    end
  end

  register_adapter("sqlite3", Adapter::SQLite3)
end
