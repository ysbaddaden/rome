require "db"
require "./adapter/*"

module Rome
  class Error < Exception; end

  class RecordNotFound < Error; end

  @@adapter_class : Adapter.class | Nil
  @@connection : DB::Database?
  @@database_url : String?

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

  def self.new_connection : DB::Database
    DB.open(database_url)
  end

  def self.connection : DB::Database
    @@connection ||= new_connection
  end

  def self.connection
    connection.using_connection { |db| yield db }
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

    private def __rome_log(sql, args)
      rs = nil
      spent = Time.measure { rs = yield }

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

      rs.not_nil!
    end
  end
{% end %}
