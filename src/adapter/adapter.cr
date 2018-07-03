module Rome
  abstract struct Adapter
    private getter builder : QueryBuilder

    def initialize(@builder)
    end

    # abstract def self.quote(name : Symbol | String, io : IO)

    def quote(name : Symbol | String, io : IO)
      self.class.quote(name, io)
    end

    def insert(attributes : Hash | NamedTuple) : Nil
      rs = Rome.connection &.exec(*insert_sql(attributes))
      yield rs.last_insert_id
    end

    def select_one
      return if @builder.none?
      Rome.connection &.query_one?(*select_sql) { |rs| yield rs }
    end

    def select_all(&block : DB::ResultSet -> U) : Array(U) forall U
      if @builder.none?
        Array(U).new(0)
      else
        Rome.connection &.query_all(*select_sql) { |rs| yield rs }
      end
    end

    def select_each : Nil
      return if @builder.none?
      Rome.connection &.query_each(*select_sql) { |rs| yield rs }
    end

    def scalar
      Rome.connection &.scalar(*select_sql)
    end

    def update(attributes : Hash | NamedTuple) : Nil
      return if @builder.none?
      Rome.connection &.exec(*update_sql(attributes))
    end

    def delete : Nil
      return if @builder.none?
      Rome.connection &.exec(*delete_sql)
    end

    def to_sql : String
      sql, _ = select_sql
      sql
    end

    protected def insert_sql(attributes) : {String, Array(Value)}
      args = [] of Value
      sql = String.build do |str|
        build_insert(attributes, str, args)
      end
      {sql, args}
    end

    protected def select_sql
      args = [] of Value
      sql = String.build do |str|
        build_select(str)
        build_where(str, args)
        build_order_by(str)
        build_limit(str)
      end
      {sql, args}
    end

    protected def update_sql(attributes) : {String, Array(Value)}
      args = [] of Value
      sql = String.build do |str|
        build_update(attributes, str, args)
        build_where(str, args)
      end
      {sql, args}
    end

    protected def delete_sql : {String, Array(Value)}
      args = [] of Value
      sql = String.build do |str|
        build_delete(str)
        build_where(str, args)
      end
      {sql, args}
    end

    protected def build_select(io) : Nil
      io << "SELECT "
      io << "DISTINCT " if builder.distinct?

      if selects = builder.selects?
        selects.each_with_index do |column_name, index|
          io << ", " unless index == 0
          case column_name
          when Symbol
            quote(column_name, io)
          when String
            io << column_name
          end
        end
      else
        io << '*'
      end
      io << " FROM "
      quote(builder.table_name, io)
    end

    private def build_insert(attributes : Hash, io, args)
      io << "INSERT INTO "
      quote(builder.table_name, io)
      io << " ("
      attributes.each_with_index do |(column_name, _), index|
        io << ", " unless index == 0
        quote(column_name, io)
      end
      io << ") VALUES ("
      attributes.each_with_index do |(_, value), index|
        args << value
        io << ", " unless index == 0
        io << '?'
      end
      io << ')'
    end

    private def build_insert(attributes : NamedTuple, io, args)
      io << "INSERT INTO "
      quote(builder.table_name, io)
      io << " ("
      attributes.each_with_index do |column_name, _, index|
        io << ", " unless index == 0
        quote(column_name, io)
      end
      io << ") VALUES ("
      attributes.each_with_index do |_, value, index|
        args << value
        io << ", " unless index == 0
        io << '?'
      end
      io << ')'
    end

    private def build_update(attributes : Hash, io, args)
      io << "UPDATE "
      quote(builder.table_name, io)
      io << " SET "
      attributes.each_with_index do |(column_name, value), index|
        args << value
        io << ", " unless index == 0
        quote(column_name, io)
        io << " = ?"
      end
    end

    private def build_update(attributes : NamedTuple, io, args)
      io << "UPDATE "
      quote(builder.table_name, io)
      io << " SET "
      attributes.each_with_index do |column_name, value, index|
        args << value
        io << ", " unless index == 0
        quote(column_name, io)
        io << " = ?"
      end
    end

    private def build_delete(io : IO) : Nil
      io << "DELETE FROM "
      quote(builder.table_name, io)
    end

    protected def build_where(io, args) : Nil
      return unless conditions = builder.conditions?

      io << " WHERE "
      conditions.each_with_index do |condition, index|
        io << " AND " unless index == 0

        case condition
        when QueryBuilder::Condition
          quote(condition.column_name, io)

          case value = condition.value
          when Array(Value)
            if condition.not
              io << " NOT IN ("
            else
              io << " IN ("
            end
            value.size.times do |index|
              io << ", " unless index == 0
              io << '?'
            end
            io << ')'
            args.concat(value)

          when nil
            if condition.not
              io << " IS NOT NULL"
            else
              io << " IS NULL"
            end

          else
            args << value
            if condition.not
              io << " <> ?"
            else
              io << " = ?"
            end
          end

        when QueryBuilder::RawCondition
          io << "NOT " if condition.not
          io << '(' << condition.raw << ')'

          if values = condition.values
            args.concat(values)
          end
        end
      end
    end

    protected def build_order_by(io) : Nil
      return unless orders = builder.orders?

      io << " ORDER BY "
      orders.each_with_index do |order, index|
        io << ", " unless index == 0

        case order
        when {Symbol, Symbol}
          column_name, direction = order.as({Symbol, Symbol})
          quote(column_name, io)
          case direction
          when :asc then io << " ASC"
          when :desc then io << " DESC"
          end
        when String
          io << order
        end
      end
    end

    protected def build_limit(io) : Nil
      if limit = builder.limit
        io << " LIMIT " << limit
      end
      if offset = builder.offset
        io << " OFFSET " << offset
      end
    end
  end

  @@adapters = {} of String => Adapter.class

  def self.adapters : Hash(String, Adapter.class)
    @@adapters
  end

  def self.register_adapter(name : String, adapter_class : Adapter.class) : Nil
    @@adapters[name] = adapter_class
  end
end
