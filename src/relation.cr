module Rome
  struct Relation(T)
    protected def initialize(@builder : QueryBuilder)
    end

    def each(&block : T ->) : Nil
      Rome.adapter_class.new(@builder).select_each do |rs|
        record = T.new(rs)
        record.new_record = false
        yield record
      end
    end

    def all : Array(T)
      Rome.adapter_class.new(@builder).select_all do |rs|
        record = T.new(rs)
        record.new_record = false
        record
      end
    end

    def find(id) : T
      find?(id) || raise RecordNotFound.new
    end

    def find?(id) : T?
      builder = @builder.where({ T.primary_key => id }).limit(1)

      Rome.adapter_class.new(builder).select_one do |rs|
        record = T.new(rs)
        record.new_record = false
        record
      end
    end

    def find_by(**args) : T
      find_by?(**args) || raise RecordNotFound.new
    end

    def find_by?(**args) : T?
      builder = @builder.where(**args).limit(1)

      Rome.adapter_class.new(builder).select_one do |rs|
        record = T.new(rs)
        record.new_record = false
        record
      end
    end

    def exists? : Bool
      builder = @builder.unscope(:select, :order, :offset)
        .select!("1 AS one")
        .limit!(1)
      Rome.adapter_class.new(builder).select_one { |rs| true } || false
    end

    def exists?(id) : Bool
      builder = @builder.unscope(:select, :order, :offset)
        .select!("1 AS one")
        .where!({ T.primary_key => id })
        .limit!(1)
      Rome.adapter_class.new(builder).select_one { |rs| true } || false
    end

    def take : T
      take? || raise RecordNotFound.new
    end

    def take? : T?
      builder = @builder.limit(1)

      Rome.adapter_class.new(builder).select_one do |rs|
        record = T.new(rs)
        record.new_record = false
        record
      end
    end

    def first : T
      first? || raise RecordNotFound.new
    end

    def first? : T?
      builder = @builder.limit(1)
      builder.order!({ T.primary_key => :asc }) unless builder.orders?

      Rome.adapter_class.new(builder).select_one do |rs|
        record = T.new(rs)
        record.new_record = false
        record
      end
    end

    def last : T
      last? || raise RecordNotFound.new
    end

    def last? : T?
      builder = @builder.limit(1)
      builder.order!({ T.primary_key => :desc }) unless builder.orders?

      Rome.adapter_class.new(builder).select_one do |rs|
        record = T.new(rs)
        record.new_record = false
        record
      end
    end

    def pluck(column_name : Symbol | String) : Array(Value)
      builder = @builder.unscope(:select)
      builder.select!(column_name)
      Rome.adapter_class.new(builder).select_all { |rs| rs.read(Value) }
    end

    def count(column_name : Symbol | String = "*", distinct = @builder.distinct?) : Int64
      calculate("COUNT", column_name, distinct).as(Int).to_i64
    end

    def sum(column_name : Symbol | String) : Int64 | Float64
      rs = calculate("SUM", column_name)
      if rs.responds_to?(:to_i64)
        rs.to_i64
      elsif rs.responds_to?(:to_f64)
        rs.to_f64
      else
        raise Error.new("expected integer or floating point number but got #{rs.class.name}")
      end
    end

    def average(column_name : Symbol | String) : Float64
      rs = calculate("AVG", column_name)
      if rs.responds_to?(:to_f64)
        rs.to_f64
      else
        raise Error.new("expected floating point number but got #{rs.class.name}")
      end
    end

    def minimum(column_name : Symbol | String)
      calculate("MIN", column_name)
    end

    def maximum(column_name : Symbol | String)
      calculate("MAX", column_name)
    end

    protected def calculate(function, column_name, distinct = @builder.distinct?)
      selects = String.build do |str|
        str << function
        str << '('
        str << "DISTINCT " if distinct
        case column_name
        when Symbol
          Rome.adapter_class.quote(column_name, str)
        when String
          str << column_name
        end
        str << ')'
      end
      builder = @builder.unscope(:select)
      builder.select!(selects)
      Rome.adapter_class.new(builder).scalar
    end

    def update(**attributes) : Nil
      Rome.adapter_class.new(@builder).update(attributes)
    end

    def delete : Nil
      Rome.adapter_class.new(@builder).delete
    end

    def select(*columns : Symbol) : self
      self.class.new @builder.select(*columns)
    end

    def select!(*columns : Symbol) : self
      @builder.select!(*columns)
      self
    end

    def select(sql : String) : self
      self.class.new @builder.select(sql)
    end

    def select!(sql : String) : self
      @builder.select!(sql)
      self
    end

    def distinct(value = true) : self
      self.class.new @builder.distinct(value)
    end

    def distinct!(value = true) : self
      @builder.distinct!(value)
    end

    def where(conditions : Hash | NamedTuple) : self
      self.class.new @builder.where(conditions)
    end

    def where!(conditions : Hash | NamedTuple) : self
      @builder.where!(conditions)
      self
    end

    def where(**conditions) : self
      self.class.new @builder.where(**conditions)
    end

    def where!(**conditions) : self
      @builder.where!(**conditions)
      self
    end

    def where(sql : String, *args : Value) : self
      self.class.new @builder.where(sql, *args)
    end

    def where!(sql : String, *args : Value) : self
      @builder.where!(sql, *args)
      self
    end

    def limit(value : Int32) : self
      self.class.new @builder.limit(value)
    end

    def limit!(value : Int32) : self
      @builder.limit!(value)
      self
    end

    def offset(value : Int32) : self
      self.class.new @builder.offset(value)
    end

    def offset!(value : Int32) : self
      @builder.offset!(value)
      self
    end

    def order(columns : Hash(Symbol, Symbol)) : self
      self.class.new @builder.order(columns)
    end

    def order!(columns : Hash(Symbol, Symbol)) : self
      @builder.order!(columns)
      self
    end

    def order(*columns : Symbol | String) : self
      self.class.new @builder.order(*columns)
    end

    def order!(*columns : Symbol | String) : self
      @builder.order!(*columns)
      self
    end

    def order(**columns) : self
      self.class.new @builder.order(**columns)
    end

    def order!(**columns) : self
      @builder.order!(**columns)
      self
    end

    def reorder(columns : Hash(Symbol, Symbol)) : self
      self.class.new @builder.reorder(columns)
    end

    def reorder!(columns : Hash(Symbol, Symbol)) : self
      @builder.reorder!(columns)
      self
    end

    def reorder(*columns : Symbol | String) : self
      self.class.new @builder.reorder(*columns)
    end

    def reorder!(*columns : Symbol | String) : self
      @builder.reorder!(*columns)
      self
    end

    def reorder(**columns) : self
      self.class.new @builder.reorder(**columns)
    end

    def reorder!(**columns) : self
      @builder.reorder!(**columns)
      self
    end

    def unscope(*args) : self
      self.class.new @builder.unscope(*args)
    end

    def unscope!(*args) : self
      @builder.unscope!(*args)
      self
    end

    def to_sql : String
      Rome.adapter_class.new(@builder).to_sql
    end
  end
end
