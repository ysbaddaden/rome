module Rome
  alias Value = String | Nil | Bool | Int32 | Int64 | Float32 | Float64 | Time | UUID

  # :nodoc:
  struct QueryBuilder
    alias Selects = Array(Symbol | String)
    alias Conditions = Array({Symbol, Value} | {String, Array(Value)})
    alias Orders = Array({Symbol, Symbol} | String)

    property table_name : String
    property primary_key : String
    property selects : Selects?
    property conditions : Conditions?
    property orders : Orders?
    property limit : Int32?
    property offset : Int32?

    def initialize(@table_name, @primary_key = "")
    end

    def selects? : Selects?
      return unless selects = @selects
      return if selects.empty?
      selects
    end

    def conditions? : Conditions?
      return unless conditions = @conditions
      return if conditions.empty?
      conditions
    end

    def orders? : Orders?
      return unless orders = @orders
      return if orders.empty?
      orders
    end

    def select(*columns : Symbol | String) : self
      builder = dup
      builder.selects = @selects.dup
      builder.select!(*columns)
      builder
    end

    def select!(*columns : Symbol | String) : self
      actual = @selects ||= Selects.new
      columns.each { |name| actual << name }
      self
    end

    def where(conditions : Hash | NamedTuple) : self
      builder = dup
      builder.conditions = @conditions.dup.as(Conditions?)
      builder.where!(conditions)
    end

    def where!(conditions : Hash | NamedTuple) : self
      actual = @conditions ||= Conditions.new
      conditions.each { |k, v| actual << {k, v} }
      self
    end

    def where(raw : String, *args : Value) : self
      builder = dup
      builder.conditions = @conditions.dup.as(Conditions?)
      builder.where!(raw, *args)
    end

    def where!(raw : String, *args : Value) : self
      actual = @conditions ||= Conditions.new
      if args.empty?
        actual << {raw, nil}
      else
        actual << {raw, Array(Value).new(args.size) { |i| args[i] }}
      end
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
      actual = @orders ||= Orders.new
      columns.each { |name, direction| actual << {name, direction} }
      self
    end

    def order(*columns : Symbol | String) : self
      builder = dup
      builder.orders = @orders.dup
      builder.order!(*columns)
    end

    def order!(*columns : Symbol | String) : self
      actual = @orders ||= Orders.new
      columns.each do |value|
        case value
        when Symbol
          actual << {value, :asc}
        when String
          actual << value
        end
      end
      self
    end

    def order(**columns) : self
      builder = dup
      builder.orders = @orders.dup
      builder.order!(**columns)
    end

    def order!(**columns) : self
      actual = @orders ||= Orders.new
      columns.each { |name, direction| actual << {name, direction} }
      self
    end

    def reorder(columns : Hash(Symbol, Symbol)) : self
      builder = dup
      builder.orders = Orders.new
      builder.order!(columns)
    end

    def reorder!(columns : Hash(Symbol, Symbol)) : self
      @orders.try(&.clear)
      order!(columns)
    end

    def reorder(*columns : Symbol | String) : self
      builder = dup
      builder.orders = Orders.new
      builder.order!(*columns)
    end

    def reorder!(*columns : Symbol | String) : self
      @orders.try(&.clear)
      order!(*columns)
    end

    def reorder(**columns) : self
      builder = dup
      builder.orders = Orders.new
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
