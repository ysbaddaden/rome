require "./adapter"

module Rome
  struct Adapter::MySQL < Adapter
    def self.quote(name : Symbol | String, io : IO)
      io << '`'
      name.to_s(io)
      io << '`'
    end
  end

  register_adapter("mysql", Adapter::MySQL)
end
