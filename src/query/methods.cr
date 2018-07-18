require "./builder"
require "../relation"

module Rome
  # Except for the following methods, most methods are mere redirection to
  # `Relation(T)` that you can refer to for documentation.
  #
  # - `#find_all_by_sql`
  # - `#find_one_by_sql`
  # - `#find_one_by_sql?`
  module Query::Methods
    # Initiates a SQL query.
    def query : Relation(self)
      {% begin %}
        Relation({{@type}}).new(Query::Builder.new(table_name))
      {% end %}
    end

    def each : Nil
      query.each { yield rs }
    end

    def each : Iterator
      query.each
    end

    def all : Relation(self)
      query.all
    end

    def ids : Array
      query.ids
    end

    def find(id) : self
      query.find(id)
    end

    def find?(id) : self?
      query.find?(id)
    end

    def exists?(id) : Bool
      query.exists?(id)
    end

    def find_by(**args) : self
      query.find_by(**args)
    end

    def find_by?(**args) : self?
      query.find_by?(**args)
    end

    # Loads records by raw SQL query. You may refer to arguments with `?` in the
    # SQL query, and pass them to the method. For example:
    #
    # ```
    # users = User.find_all_by_sql(<<-SQL, "julien")
    #   SELECT * FROM "users" WHERE username = ?
    #   SQL
    # ```
    def find_all_by_sql(sql : String, *args) : Array(self)
      Rome.connection &.query_all(sql, *args) { |rs| new(rs) }
    end

    # Loads one record by raw SQL query. You may refer to arguments with `?` in
    # the SQL query, and pass them to the method. For example:
    #
    # ```
    # user = User.find_one_by_sql(<<-SQL, "julien")
    #   SELECT * FROM "users" WHERE username = ? LIMIT 1
    #   SQL
    # ```
    #
    # Raises a `RecordNotFound` exception when no record could be found in the
    # database.
    def find_one_by_sql(sql : String, *args) : self
      Rome.connection &.query_one?(sql, *args) { |rs| new(rs) } || raise RecordNotFound.new
    end

    # Same as `#find_one_by_sql` but returns `nil` when no record could be found
    # in the database.
    def find_one_by_sql?(sql : String, *args) : self?
      Rome.connection &.query_one?(sql, *args) { |rs| new(rs) }
    end

    def take : self
      query.take
    end

    def take? : self?
      query.take?
    end

    def first : self
      query.first
    end

    def first? : self?
      query.first?
    end

    def last : self
      query.last
    end

    def last? : self?
      query.last?
    end

    def pluck(column_name : Symbol | String) : Array(Value)
      query.pluck(column_name)
    end

    def count(column_name : Symbol | String = "*", distinct = false) : Int64
      query.count(column_name, distinct)
    end

    def sum(column_name : Symbol | String) : Int64 | Float64
      query.sum(column_name)
    end

    def average(column_name : Symbol | String) : Float64
      query.average(column_name)
    end

    def minimum(column_name : Symbol | String)
      query.minimum(column_name)
    end

    def maximum(column_name : Symbol | String)
      query.maximum(column_name)
    end

    def none : Relation(self)
      query.none
    end

    def select(*columns : Symbol) : Relation(self)
      query.select(*columns)
    end

    def select(sql : String) : Relation(self)
      query.select(sql)
    end

    def distinct(value = true) : Relation(self)
      query.distinct(value)
    end

    def where(conditions : Hash(Symbol, Value | Array(Value)) | NamedTuple) : Relation(self)
      query.where(conditions)
    end

    def where(**conditions) : Relation(self)
      query.where(**conditions)
    end

    def where(sql : String, *args : Value) : Relation(self)
      query.where(sql, *args)
    end

    def limit(value : Int32) : Relation(self)
      query.limit(value)
    end

    def offset(value : Int32) : Relation(self)
      query.offset(value)
    end

    def order(columns : Hash(Symbol, Symbol)) : Relation(self)
      query.order(columns)
    end

    def order(*columns : Symbol | String) : Relation(self)
      query.order(*columns)
    end

    def order(**columns) : Relation(self)
      query.order(**columns)
    end

    def reorder(columns : Hash(Symbol, Symbol)) : Relation(self)
      query.reorder(columns)
    end

    def reorder(*columns : Symbol | String) : Relation(self)
      query.reorder(*columns)
    end

    def reorder(**columns) : Relation(self)
      query.reorder(**columns)
    end

    # :nodoc:
    #macro set_methods(properties, strict)
    #  # :nodoc:
    #  def find_by(
    #    {% if strict %}
    #      {% for key, opts in properties %}
    #        {% unless opts[:null] || opts[:default] %}
    #          {{key}} : {{opts[:ivar_type]}},
    #        {% end %}
    #      {% end %}
    #    {% end %}
    #    {% for key, opts in properties %}
    #      {% if !strict || opts[:null] || opts[:default] %}
    #        {{key}} : {{opts[:ivar_type]}} = {{opts[:default] || "nil".id }},
    #      {% end %}
    #    {% end %}
    #  ) : self
    #    query.find_by(**args)
    #  end
    #
    #  # :nodoc:
    #  def find_by?(
    #    {% if strict %}
    #      {% for key, opts in properties %}
    #        {% unless opts[:null] || opts[:default] %}
    #          {{key}} : {{opts[:ivar_type]}},
    #        {% end %}
    #      {% end %}
    #    {% end %}
    #    {% for key, opts in properties %}
    #      {% if !strict || opts[:null] || opts[:default] %}
    #        {{key}} : {{opts[:ivar_type]}} = {{opts[:default] || "nil".id }},
    #      {% end %}
    #    {% end %}
    #  ) : self?
    #    query.find_by?(**args)
    #  end
    #
    #  # :nodoc:
    #  def where(
    #    {% for key, opts in properties %}
    #      {{key}} : {{opts[:nilable_type]}} = nil,
    #    {% end %}
    #  ) : self?
    #    query.where(**args)
    #  end
    #end
  end
end
