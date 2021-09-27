require "./test_helper"

module Rome
  class Adapter::PostgreSQLTest < AdapterTest
    def adapter(builder = @builder)
      Adapter::PostgreSQL.new(builder)
    end

    def test_select
      assert_sql %(SELECT * FROM "users"), adapter.select_sql

      @builder.select!(:name, "1 AS one")
      assert_sql %(SELECT "name", 1 AS one FROM "users"), adapter.select_sql
    end

    def test_select_distinct
      @builder.distinct!
      assert_sql %(SELECT DISTINCT * FROM "users"), adapter.select_sql

      @builder.distinct!(false)
      assert_sql %(SELECT * FROM "users"), adapter.select_sql
    end

    def test_select_where
      @builder.where!(name: "tom")
      @builder.where!({ :name => "alice", :group_id => 1 })
      @builder.where!("about LIKE ?", "tom%")

      assert_sql({
        %(SELECT * FROM "users" WHERE "name" = $1 AND "name" = $2 AND "group_id" = $3 AND (about LIKE $4)),
        ["tom", "alice", 1, "tom%"]
      }, adapter.select_sql)

      @builder.unscope!(:where)
      @builder.where!(name: "tom", group_id: 1)

      assert_sql({
        %(SELECT * FROM "users" WHERE "name" = $1 AND "group_id" = $2), ["tom", 1]
      }, adapter.select_sql)
    end

    def test_select_where_not
      @builder.where_not!(name: "tom")
      @builder.where_not!({ :name => "alice", :group_id => 1 })
      @builder.where_not!("about LIKE ?", "tom%")

      assert_sql({
        %(SELECT * FROM "users" WHERE "name" <> $1 AND "name" <> $2 AND "group_id" <> $3 AND NOT (about LIKE $4)),
        ["tom", "alice", 1, "tom%"]
      }, adapter.select_sql)

      @builder.unscope!(:where)
      @builder.where!(name: "tom", group_id: 1)

      assert_sql({
        %(SELECT * FROM "users" WHERE "name" = $1 AND "group_id" = $2), ["tom", 1]
      }, adapter.select_sql)
    end

    def test_select_where_in
      @builder.where!(id: [1, 3, 4])

      assert_sql({
        %(SELECT * FROM "users" WHERE "id" IN ($1, $2, $3)), [1, 3, 4],
      }, adapter.select_sql)
    end

    def test_select_where_not_in
      @builder.where_not!(id: [1, 3, 4])

      assert_sql({
        %(SELECT * FROM "users" WHERE "id" NOT IN ($1, $2, $3)), [1, 3, 4],
      }, adapter.select_sql)
    end

    def test_select_where_regex
      @builder.where!(name: /jul/)
      @builder.where!(name: /a[bc]/i)
      assert_sql({
        %(SELECT * FROM "users" WHERE "name" ~ $1 AND "name" ~* $2),
        ["jul", "a[bc]"]
      }, adapter.select_sql)
    end

    def test_select_where_not_regex
      @builder.where_not!(name: /jul/)
      @builder.where_not!(name: /a[bc]/i)
      assert_sql({
        %(SELECT * FROM "users" WHERE "name" !~ $1 AND "name" !~* $2),
        ["jul", "a[bc]"]
      }, adapter.select_sql)
    end

    def test_select_order
      @builder.order!(:name)
      assert_sql %(SELECT * FROM "users" ORDER BY "name" ASC), adapter.select_sql

      @builder.unscope!(:order)
      @builder.order!(group_id: :desc, name: :asc)
      assert_sql %(SELECT * FROM "users" ORDER BY "group_id" DESC, "name" ASC), adapter.select_sql

      @builder.unscope!(:order)
      @builder.order!("name DESC NULLS LAST")
      assert_sql %(SELECT * FROM "users" ORDER BY name DESC NULLS LAST), adapter.select_sql
    end

    def test_select_reorder
      @builder.reorder!(:name)
      assert_sql %(SELECT * FROM "users" ORDER BY "name" ASC), adapter.select_sql

      @builder.reorder!(name: :desc)
      assert_sql %(SELECT * FROM "users" ORDER BY "name" DESC), adapter.select_sql

      @builder.reorder!({ :name => :asc, :about => :desc })
      assert_sql %(SELECT * FROM "users" ORDER BY "name" ASC, "about" DESC), adapter.select_sql

      @builder.reorder!("name DESC NULLS FIRST")
      assert_sql %(SELECT * FROM "users" ORDER BY name DESC NULLS FIRST), adapter.select_sql
    end

    def test_select_limit_and_offset
      @builder.limit!(10)
      assert_sql %(SELECT * FROM "users" LIMIT 10), adapter.select_sql

      @builder.offset!(200)
      assert_sql %(SELECT * FROM "users" LIMIT 10 OFFSET 200), adapter.select_sql
    end

    def test_insert
      uuid = UUID.random

      assert_sql({
        %(INSERT INTO "users" ("uuid") VALUES ($1) RETURNING "uuid"), [uuid]
      }, adapter.insert_sql({ uuid: uuid }))

      assert_sql({
        %(INSERT INTO "users" ("name", "about") VALUES ($1, $2) RETURNING "uuid"),
        ["julien", nil]
      }, adapter.insert_sql({ name: "julien", about: nil }))

      assert_sql({
        %(INSERT INTO "users" ("name", "about") VALUES ($1, $2) RETURNING "uuid"),
        ["julien", ""]
      }, adapter.insert_sql({ :name => "julien", :about => "" }))

      assert_sql({
        %(INSERT INTO "suppliers" DEFAULT VALUES RETURNING "id"), [] of String
      }, adapter(Query::Builder.new("suppliers", "id")).insert_sql({} of String => String))
    end

    def test_update
      assert_sql({
        %(UPDATE "users" SET "name" = $1), ["alice"]
      }, adapter.update_sql({ name: "alice" }))
    end

    def test_update_where
      uuid = UUID.random
      @builder.where!(uuid: uuid)

      assert_sql({
        %(UPDATE "users" SET "name" = $1, "about" = $2 WHERE "uuid" = $3), ["alice", nil, uuid]
      }, adapter.update_sql({ "name" => "alice", :about => nil }))
    end

    def test_delete
      assert_sql %(DELETE FROM "users"), adapter.delete_sql
    end

    def test_delete_where
      uuid = UUID.random
      @builder.where!(uuid: uuid)

      assert_sql({
        %(DELETE FROM "users" WHERE "uuid" = $1), [uuid]
      }, adapter.delete_sql)
    end
  end
end
