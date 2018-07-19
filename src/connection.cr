require "db"
require "./adapter/*"

module Rome
  class Error < Exception; end

  class RecordNotFound < Error; end

  @@adapter_class : Adapter.class | Nil
  @@database_url : String?
  @@pool : DB::Database?
  @@connections = {} of LibC::ULong => DB::Connection
  @@transactions = {} of LibC::ULong => DB::Transaction

  def self.database_url
    @@database_url ||= ENV["DATABASE_URL"]
  end

  def self.database_url=(@@database_url)
  end

  def self.adapter_class
    @@adapter_class ||= begin
      scheme = URI.parse(database_url).scheme
      Rome.adapters[scheme]? || raise "unsupported database engine: #{scheme}"
    end
  end

  def self.pool : DB::Database
    @@pool ||= DB.open(database_url)
  end

  def self.checkout : DB::Connection
    @@connections[Fiber.current.object_id] ||= pool.checkout
  end

  def self.release : Nil
    @@connections.delete(Fiber.current.object_id).try(&.release)
    if tx = @@transactions.delete(Fiber.current.object_id)
      tx.rollback unless tx.closed?
    end
  end

  def self.with_connection
    if db = @@connections[Fiber.current.object_id]?
      yield db
    else
      begin
        yield checkout
      ensure
        release
      end
    end
  end

  def self.connection
    if db = @@connections[Fiber.current.object_id]?
      yield db
    else
      pool.using_connection { |db| yield db }
    end
  end

  def self.begin_transaction : DB::Transaction
    @@transactions[Fiber.current.object_id] ||= checkout.begin_transaction
  end

  def self.transaction
    if tx = @@transactions[Fiber.current.object_id]?
      transaction(tx.begin_transaction) { |tx| yield tx }
    else
      Rome.with_connection do |conn|
        transaction(conn.begin_transaction) { |tx| yield tx }
      end
    end
  end

  private def self.transaction(tx : DB::Transaction)
    id = Fiber.current.object_id
    @@transactions[id] = tx

    begin
      yield tx
    rescue ex
      tx.rollback unless tx.closed?
      raise ex unless ex.is_a?(DB::Rollback)
    else
      tx.commit unless tx.closed?
    ensure
      case tx
      when DB::TopLevelTransaction
        @@transactions.delete(id)
      when DB::SavePointTransaction
        @@transactions[id] = tx.@parent
      else
        raise "unsupported transaction type: #{tx.class.name}"
      end
    end
  end
end

{% if flag?(:ROME_DEBUG) %}
  require "colorize"

  module DB::QueryMethods
    def query(sql, *args)
      __rome_log(sql, args) { build(sql).query(*args) }
    end

    def exec(sql, *args)
      __rome_log(sql, args) { build(sql).exec(*args) }
    end

    def scalar(sql, *args)
      __rome_log(sql, args) { build(sql).scalar(*args) }
    end

    private def __rome_log(sql, args)
      rs = nil
      error = nil

      spent = Time.measure do
        begin
          rs = yield
        rescue ex
          error = ex
        end
      end

      log = String.build do |str|
        Colorize::Object.new("").fore(:light_magenta).surround(str) do
          str << "SQL ("
          spent.total_milliseconds.round(2).to_s(str)
          str << "ms)  "
        end
        str << sql.gsub(/\s+/, ' ')
        str << ' '
        str << '['
        args.each_with_index do |arg, index|
          str << ", " unless index == 0
          arg.inspect(str)
        end
        str << ']'
      end

      STDERR.puts(log)

      raise error if error
      rs.not_nil!
    end
  end
{% end %}
