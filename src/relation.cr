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

    def first : T
      first? || raise RecordNotFound.new
    end

    def first? : T?
      builder = @builder.limit(1)
      builder = builder.order({ T.primary_key => :asc }) unless builder.orders?

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
      builder = builder.order({ T.primary_key => :desc }) unless builder.orders?

      Rome.adapter_class.new(builder).select_one do |rs|
        record = T.new(rs)
        record.new_record = false
        record
      end
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

    def order(*columns : Symbol) : self
      self.class.new @builder.order(*columns)
    end

    def order!(*columns : Symbol) : self
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

    def reorder(*columns : Symbol) : self
      self.class.new @builder.reorder(*columns)
    end

    def reorder!(*columns : Symbol) : self
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
