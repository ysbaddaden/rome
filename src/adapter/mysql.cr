require "./adapter"

module Rome
  struct Adapter::MySQL < Adapter
    def self.quote(name : Symbol | String, io : IO)
      io << '`'
      name.to_s(io)
      io << '`'
    end

    protected def build_where_regex(condition, io, args)
      re = condition.value.as(Regex)
      args << re.source

      io << "NOT (" if condition.not
      io << "BINARY " unless re.options.ignore_case?
      quote(condition.column_name, io)
      io << " REGEXP ?"
      io << ')' if condition.not
    end
  end

  register_adapter("mysql", Adapter::MySQL)
end
