require "../test_helper"

module Rome
  class AdapterTest < Minitest::Test
    @builder = Query::Builder.new("users", "uuid")

    protected def assert_sql(expected : String, actual, message = nil, file = __FILE__, line = __LINE__)
      assert_equal expected.gsub(/\s+/, ' '), actual[0], message, file, line
    end

    protected def assert_sql(expected : Tuple, actual, message = nil, file = __FILE__, line = __LINE__)
      sql, values = expected
      assert_equal sql.gsub(/\s+/, ' '), actual[0], message, file, line
      assert_equal values, actual[1], message, file, line
    end
  end
end
