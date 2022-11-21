require "./iterator"

module Rome
  module Query
    module Cache(T)
      @cache : Array(T)?

      def to_a : Array(T)
        @cache ||= Rome.adapter_class.new(builder).select_all { |rs| T.new(rs) }
      end

      # Iterates all records loaded from the database.
      def each(&block : T ->) : Nil
        to_a.each { |record| yield record }
      end

      # Iterates all records if previously loaded from the database, or iterates
      # records directly streamed from the database otherwise.
      def each
        if cache = @cache
          cache.each
        else
          Iterator(T).new(builder)
        end
      end

      def reload
        @cache = nil
        to_a
      end

      def cached?
        !@cache.nil?
      end
    end
  end
end
