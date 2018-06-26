require "./adapter"

module Rome
  struct Adapter::PostgreSQL < Adapter
    def insert(attributes : Hash | NamedTuple)
      Rome.connection &.query_one(*insert_sql(attributes)) do |rs|
        yield rs.read
      end
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
        io << '$' << args.size
      end
      io << ") RETURNING " << builder.primary_key
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
        io << '$' << args.size
      end
      io << ") RETURNING " << builder.primary_key
    end

    private def build_update(attributes : Hash, io, args)
      io << "UPDATE " << builder.table_name << " SET "
      attributes.each_with_index do |(column_name, value), index|
        args << value
        io << ", " unless index == 0
        column_name.to_s(io)
        io << " = $" << args.size
      end
    end

    private def build_update(attributes : NamedTuple, io, args)
      io << "UPDATE " << builder.table_name << " SET "
      attributes.each_with_index do |column_name, value, index|
        args << value
        io << ", " unless index == 0
        column_name.to_s(io)
        io << " = $" << args.size
      end
    end

    protected def build_where(io, args) : Nil
      return unless conditions = builder.conditions?

      io << " WHERE "
      conditions.each_with_index do |(column_name, value), index|
        args << value
        io << " AND " unless index == 0
        column_name.to_s(io)
        io << " = $" << args.size
      end
    end
  end

  register_adapter("postgres", Adapter::PostgreSQL)
end
