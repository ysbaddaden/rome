module Rome
  alias Value = String | Nil | Bool | Int32 | Int64 | Float32 | Float64 | Time | UUID

  # :nodoc:
  struct QueryBuilder
    property table_name : String
    property primary_key : String
    property selects : Array(Symbol)?
    property conditions : Hash(Symbol, Value)?
    property orders : Array(Tuple(Symbol, Symbol))?
    property limit : Int32?
    property offset : Int32?

    def selects?
      return unless selects = @selects
      return if selects.empty?
      selects
    end

    def conditions?
      return unless conditions = @conditions
      return if conditions.empty?
      conditions
    end

    def orders?
      return unless orders = @orders
      return if orders.empty?
      orders
    end

    def initialize(@table_name, @primary_key = "")
    end

    def select(*columns : Symbol) : self
      builder = dup
      builder.selects = @selects.dup
      builder.select!(*columns)
      builder
    end

    def select!(*columns : Symbol) : self
      actual = @selects ||= [] of Symbol
      columns.each { |name| actual << name }
      self
    end

    def where(conditions : Hash | NamedTuple) : self
      builder = dup
      builder.conditions = @conditions.dup
      builder.where!(conditions)
    end

    def where!(conditions : Hash | NamedTuple) : self
      actual = @conditions ||= {} of Symbol => Value
      conditions.each { |k, v| actual[k] = v }
      self
    end

    def where(**conditions) : self
      where(conditions)
    end

    def where!(**conditions) : self
      where!(conditions)
    end

    def limit(value : Int32) : self
      builder = dup
      builder.limit!(value)
    end

    def limit!(@limit : Int32) : self
      self
    end

    def offset(value : Int32) : self
      builder = dup
      builder.offset!(value)
    end

    def offset!(@offset : Int32) : self
      self
    end

    def order(columns : Hash(Symbol, Symbol)) : self
      builder = dup
      builder.orders = @orders.dup
      builder.order!(columns)
    end

    def order!(columns : Hash(Symbol, Symbol)) : self
      actual = @orders ||= [] of {Symbol, Symbol}
      columns.each { |name, direction| actual << {name, direction} }
      self
    end

    def order(*columns : Symbol) : self
      builder = dup
      builder.orders = @orders.dup
      builder.order!(*columns)
    end

    def order!(*columns : Symbol) : self
      actual = @orders ||= [] of {Symbol, Symbol}
      columns.each { |name| actual << {name, :none} }
      self
    end

    def order(**columns) : self
      builder = dup
      builder.orders = @orders.dup
      builder.order!(**columns)
    end

    def order!(**columns) : self
      actual = @orders ||= [] of {Symbol, Symbol}
      columns.each { |name, direction| actual << {name, direction} }
      self
    end

    def reorder(columns : Hash(Symbol, Symbol)) : self
      builder = dup
      builder.orders = [] of {Symbol, Symbol}
      builder.order!(columns)
    end

    def reorder!(columns : Hash(Symbol, Symbol)) : self
      @orders.try(&.clear)
      order!(columns)
    end

    def reorder(*columns : Symbol) : self
      builder = dup
      builder.orders = [] of {Symbol, Symbol}
      builder.order!(*columns)
    end

    def reorder!(*columns : Symbol) : self
      @orders.try(&.clear)
      order!(*columns)
    end

    def reorder(**columns) : self
      builder = dup
      builder.orders = [] of {Symbol, Symbol}
      builder.order!(**columns)
    end

    def reorder!(**columns) : self
      @orders.try(&.clear)
      order!(**columns)
    end

    def unscope(*args : Symbol) : self
      builder = dup
      builder.unscope!(*args)
    end

    def unscope!(*args : Symbol) : self
      args.each do |arg|
        case arg
        when :select then @selects = nil
        when :where then @conditions = nil
        when :order then @orders = nil
        when :limit then @limit = nil
        when :offset then @offset = nil
        else raise "unknown property to unscope: #{arg}"
        end
      end
      self
    end
  end
end
