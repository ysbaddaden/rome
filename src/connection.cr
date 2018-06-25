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
  module DB::QueryMethods
    def query(sql, *args)
      __rome_log(sql, args)
      build(sql).query(*args)
    end

    def exec(sql, *args)
      __rome_log(sql, args)
      build(sql).exec(*args)
    end

    private def __rome_log(sql, args) : Nil
      log = String.build do |str|
        str << "DB: "
        sql.gsub('\n', ' ').inspect(str)
        str << ' '
        str << '['
        args.each_with_index do |arg, index|
          str << ", " unless index == 0
          arg.inspect(str)
        end
        str << ']'
      end
      STDERR.puts log
    end
  end
{% end %}
