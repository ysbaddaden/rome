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

    def self.find_all_by_sql(sql : String, *args) : Array(self)
      Rome.connection &.query_all(sql, *args) do |rs|
        record = new(rs)
        record.new_record = false
        record
      end
    end

    def self.find_one_by_sql(sql : String, *args) : self
      found = Rome.connection &.query_one?(sql, *args) do |rs|
        record = new(rs)
        record.new_record = false
        record
      end
      found || raise RecordNotFound.new
    end

    def self.find_one_by_sql?(sql : String, *args) : self?
      Rome.connection &.query_one?(sql, *args) do |rs|
        record = new(rs)
        record.new_record = false
        record
      end
    end

    def self.exists?(id) : Bool
      query.exists?(id)
    end

    def self.take : self
      query.take
    end

    def self.take? : self?
      query.take?
    end

    def self.first : self
      query.first
    end

    def self.first? : self?
      query.first?
    end

    def self.last : self
      query.last
    end

    def self.last? : self?
      query.last?
    end

    def self.pluck(column_name : Symbol | String) : Array(Value)
      query.pluck(column_name)
    end

    def self.count(column_name : Symbol | String = "*", distinct = false) : Int64
      query.count(column_name, distinct)
    end

    def self.sum(column_name : Symbol | String) : Int64 | Float64
      query.sum(column_name)
    end

    def self.average(column_name : Symbol | String) : Float64
      query.average(column_name)
    end

    def self.minimum(column_name : Symbol | String)
      query.minimum(column_name)
    end

    def self.maximum(column_name : Symbol | String)
      query.maximum(column_name)
    end

    def self.select(*columns : Symbol) : Relation(self)
      query.select(*columns)
    end

    def self.select!(*columns : Symbol) : Relation(self)
      query.select!(*columns)
    end

    def self.select(sql : String) : Relation(self)
      query.select(sql)
    end

    def self.select!(sql : String) : Relation(self)
      query.select!(sql)
    end

    def self.distinct(value = true) : Relation(self)
      query.distinct(value)
    end

    def self.distinct!(value = true) : Relation(self)
      query.distinct!(value)
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

    def self.where(sql : String, *args : Value) : Relation(self)
      query.where(sql, *args)
    end

    def self.where!(sql : String, *args : Value) : Relation(self)
      query.where!(sql, *args)
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

    def self.order(columns : Hash(Symbol, Symbol)) : Relation(self)
      query.order(columns)
    end

    def self.order!(columns : Hash(Symbol, Symbol)) : Relation(self)
      query.order!(columns)
    end

    def self.order(*columns : Symbol | String) : Relation(self)
      query.order(*columns)
    end

    def self.order!(*columns : Symbol | String) : Relation(self)
      query.order!(*columns)
    end

    def self.order(**columns) : Relation(self)
      query.order(**columns)
    end

    def self.order!(**columns) : Relation(self)
      query.order!(**columns)
    end

    def self.reorder(columns : Hash(Symbol, Symbol)) : Relation(self)
      query.reorder(columns)
    end

    def self.reorder!(columns : Hash(Symbol, Symbol)) : Relation(self)
      query.reorder!(columns)
    end

    def self.reorder(*columns : Symbol | String) : Relation(self)
      query.reorder(*columns)
    end

    def self.reorder!(*columns : Symbol | String) : Relation(self)
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
