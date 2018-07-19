require "./query/methods"
require "./query/cache"

module Rome
  struct Relation(T)
    include Enumerable(T)
    include Query::Methods(T)
    include Query::Cache(T)

    # :nodoc:
    def self.new(record : Model, foreign_key : Symbol)
      if record.id?
        builder = ::Rome::Query::Builder.new(T.table_name, T.primary_key.to_s)
        builder.where!({ foreign_key => record.id })
        new(record, foreign_key, builder)
      else
        raise RecordNotSaved.new("can't initialize Relation(#{T.name}) for #{record.class.name} doesn't have an id.")
      end
    end

    # :nodoc:
    protected def initialize(@record : Model, @foreign_key : Symbol, @builder : Query::Builder)
    end

    def build(**attributes) : T
      record = T.new(**attributes)
      record[@foreign_key] = @record.id
      # TODO: should be added to the cache?
      record
    end

    def create(**attributes) : T
      record = build(**attributes)
      record.save
      record
    end

    def delete(*records : T) : Nil
      ids = records.map(&.id)
      where({ T.primary_key => ids.to_a }).delete_all
      @cache.try(&.reject! { |r| ids.includes?(r.id) })
    end

    protected def dup(builder : Query::Builder) : self
      Relation(T).new(@record, @foreign_key, builder)
    end
  end
end
