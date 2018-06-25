require "./adapter"

module Rome
  struct Adapter::MySQL < Adapter
  end

  register_adapter("mysql", Adapter::MySQL)
end
