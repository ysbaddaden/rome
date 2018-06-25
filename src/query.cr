require "./query_builder"
require "./relation"

module Rome
  abstract class Model
    def self.query : Relation(self)
      {% begin %}
        Relation({{@type}}).new(QueryBuilder.new(table_name))
      {% end %}
    end

    def self.each : Nil
      query.each { yield rs }
    end

    def self.all : Array(self)
      query.all
    end

    def self.find(id) : self
      query.find(id)
    end

    def self.find?(id) : self?
      query.find?(id)
    end

    def self.find_by(**args) : self
      query.find_by(**args)
    end

    def self.find_by?(**args) : self?
      query.find_by?(**args)
    end

    def self.where(conditions : Hash | NamedTuple) : Relation(self)
      query.where(conditions)
    end

    def self.where!(conditions : Hash | NamedTuple) : Relation(self)
      query.where!(conditions)
    end

    def self.where(**conditions) : Relation(self)
      query.where(**conditions)
    end

    def self.where!(**conditions) : Relation(self)
      query.where!(**conditions)
    end

    def self.limit(value : Int32) : Relation(self)
      query.limit(value)
    end

    def self.limit!(value : Int32) : Relation(self)
      query.limit!(value)
    end

    def self.offset(value : Int32) : Relation(self)
      query.offset(value)
    end

    def self.offset!(value : Int32) : Relation(self)
      query.offset!(value)
    end

    def self.order(*columns : Symbol) : Relation(self)
      query.order(*columns)
    end

    def self.order!(*columns : Symbol) : Relation(self)
      query.order!(*columns)
    end

    def self.order(**columns) : Relation(self)
      query.order(**columns)
    end

    def self.order!(**columns) : Relation(self)
      query.order!(**columns)
    end

    def self.reorder(*columns : Symbol) : Relation(self)
      query.reorder(*columns)
    end

    def self.reorder!(*columns : Symbol) : Relation(self)
      query.reorder!(*columns)
    end

    def self.reorder(**columns) : Relation(self)
      query.reorder(**columns)
    end

    def self.reorder!(**columns) : Relation(self)
      query.reorder!(**columns)
    end
  end
end
