module Rome
  abstract struct Adapter
    private getter builder : QueryBuilder

    def initialize(@builder)
    end

    def insert(attributes : Hash | NamedTuple) : Nil
      rs = Rome.connection &.exec(*insert_sql(attributes))
      yield rs.last_insert_id
    end

    def select_one
      Rome.connection &.query_one?(*select_sql) { |rs| yield rs }
    end

    def select_all
      Rome.connection &.query_all(*select_sql) { |rs| yield rs }
    end

    def select_each : Nil
      Rome.connection &.query_each(*select_sql) { |rs| yield rs }
    end

    def update(attributes : Hash | NamedTuple) : Nil
      Rome.connection &.exec(*update_sql(attributes))
    end

    def delete : Nil
      Rome.connection &.exec(*delete_sql)
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
      if selects = builder.selects?
        selects.join(", ", io)
      else
        io << '*'
      end
      io << " FROM " << builder.table_name
    end

    private def build_insert(attributes : Hash, io, args)
      io << "INSERT INTO " << builder.table_name << " ("
      attributes.each_with_index do |(column_name, _), index|
        io << ", " unless index == 0
        column_name.to_s(io)
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
      io << "INSERT INTO " << builder.table_name << " ("
      attributes.each_with_index do |column_name, _, index|
        io << ", " unless index == 0
        column_name.to_s(io)
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
      io << "UPDATE " << builder.table_name << " SET "
      attributes.each_with_index do |(column_name, value), index|
        args << value
        io << ", " unless index == 0
        column_name.to_s(io)
        io << " = ?"
      end
    end

    private def build_update(attributes : NamedTuple, io, args)
      io << "UPDATE " << builder.table_name << " SET "
      attributes.each_with_index do |column_name, value, index|
        args << value
        io << ", " unless index == 0
        column_name.to_s(io)
        io << " = ?"
      end
    end

    private def build_delete(io : IO) : Nil
      io << "DELETE FROM " << builder.table_name
    end

    protected def build_where(io, args) : Nil
      return unless conditions = builder.conditions?

      io << " WHERE "
      conditions.each_with_index do |(column_name, value), index|
        args << value

        io << " AND " unless index == 0
        column_name.to_s(io)
        io << " = ?"
      end
    end

    protected def build_order_by(io) : Nil
      return unless orders = builder.orders?

      io << " ORDER BY "
      orders.each_with_index do |(column_name, direction), index|
        io << ", " unless index == 0
        column_name.to_s(io)

        case direction
        when :asc then io << " ASC"
        when :desc then io << " DESC"
        when :none
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
