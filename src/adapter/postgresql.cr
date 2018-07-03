require "./adapter"

module Rome
  struct Adapter::PostgreSQL < Adapter
    def self.quote(name : Symbol | String, io : IO)
      io << '"'
      name.to_s(io)
      io << '"'
    end

    def insert(attributes : Hash | NamedTuple)
      Rome.connection &.query_one(*insert_sql(attributes)) do |rs|
        yield rs.read
      end
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
        io << '$' << args.size
      end
      io << ") RETURNING "
      quote(builder.primary_key, io)
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
        io << '$' << args.size
      end
      io << ") RETURNING "
      quote(builder.primary_key, io)
    end

    private def build_update(attributes : Hash, io, args)
      io << "UPDATE "
      quote(builder.table_name, io)
      io << " SET "
      attributes.each_with_index do |(column_name, value), index|
        args << value
        io << ", " unless index == 0
        quote(column_name, io)
        io << " = $" << args.size
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
        io << " = $" << args.size
      end
    end

    protected def build_where(io, args) : Nil
      return unless conditions = builder.conditions?

      io << " WHERE "
      conditions.each_with_index do |condition, index|
        io << " AND " unless index == 0

        case condition[0]
        when Symbol
          quote(condition[0], io)

          case value = condition[1]
          when Array(Value)
            io << " IN ("
            value.size.times do |index|
              io << ", " unless index == 0
              io << '$' << args.size + index + 1
            end
            io << ')'
            args.concat(value)
          else
            args << value.as(Value)
            io << " = $" << args.size
          end

        when String
          case value = condition[1]
          when Array(Value)
            n = args.size
            args.concat(value)
            io << condition[0].as(String).gsub("?") { "$#{n += 1}" }
          when nil
            io << condition[0]
          else
            raise "unreachable"
          end
        else
          raise "unreachable"
        end
      end
    end
  end

  register_adapter("postgres", Adapter::PostgreSQL)
end
