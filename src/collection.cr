require "./query/methods"
require "./query/cache"

module Rome
  # Build Database Queries.
  #
  # A `Collection` is immutable: all methods will return a copy of the previous
  # `Collection` with the added constraint(s). For example:
  # ```
  # users = User.select(:id, :name).where(group_id: 2)
  # ```
  #
  # Termination methods such as `#find_by`, or `#take` will explicitely execute
  # a SQL request against the database and load one record.
  # ```
  # first_user = users.order(:name).take
  # # => SELECT "id", "name"
  # #    FROM "users"
  # #    WHERE "group_id" = 2
  # #    ORDER BY "name" ASC
  # #    LIMIT 1;
  # ```
  #
  # Termination methods such as `#to_a` or `#each` will execute a SQL request
  # then cache loaded records into the Collection, so further accesses won't
  # re-execute the SQL request. Some methods such as `#first` or `#size` will
  # leverage this cache when it's available.
  #
  # ```
  # users.to_a
  # # => SELECT "id", "name" FROM "users" WHERE "group_id" = 2;
  # ```
  #
  # When specifying column names you should always use a Symbol, so they'll be
  # properly quoted for the database server. In many cases you can specify raw
  # SQL statements using a String. For example:
  # ```
  # users = User.where("LENGTH(name) > ?", 10)
  # # => SELECT * FROM "users" WHERE LENGTH(name) > 10;
  #
  # users = User.order("LENGTH(name) DESC")
  # # => SELECT * FROM "users" ORDER BY LENGTH(name) DESC;
  #
  # count = User.count("LENGTH(name)", distinct: true)
  # # => SELECT COUNT(DISTINCT LENGTH(name)) FROM "users";
  # ```
  struct Collection(T)
    include Enumerable(T)
    include Query::Methods(T)
    include Query::Cache(T)

    protected def initialize(@builder : Query::Builder)
    end

    protected def dup(builder : Query::Builder) : self
      Collection(T).new(builder)
    end
  end
end
