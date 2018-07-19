require "./methods"

module Rome
  module Query
    # :nodoc:
    private struct Iterator(T)
      include ::Iterator(Methods(T))

      @rs : DB::ResultSet?

      def initialize(@builder : Query::Builder)
        @stop = false
      end

      def next
        return stop if @stop

        rs = @rs ||= query

        if rs.move_next
          T.new(rs)
        else
          @stop = true
          stop
        end
      end

      def stop
        if rs = @rs
          while rs.move_next; end
          rs.close
          @rs = nil
        end

        super
      end

      def rewind
        raise "can't rewind relation iterator"
      end

      private def query
        sql, args = Rome.adapter_class.new(@builder).select_sql
        Rome.connection(&.query(sql, args))
      end
    end
  end
end

