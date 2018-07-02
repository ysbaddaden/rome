require "./test_helper"

module Rome
  class Adapter::MySQLTest < AdapterTest
    protected def adapter(builder = @builder)
      Adapter::MySQL.new(builder)
    end

    def test_select
      assert_sql %(SELECT * FROM `users`), adapter.select_sql

      @builder.select!(:name, "1 AS one")
      assert_sql %(SELECT `name`, 1 AS one FROM `users`), adapter.select_sql
    end

    def test_select_where
      @builder.where!(name: "tom")
      @builder.where!({ :name => "alice", "group_id" => 1 })
      @builder.where!("about LIKE ?", "tom%")

      assert_sql({
        %(SELECT * FROM `users` WHERE `name` = ? AND `name` = ? AND `group_id` = ? AND about LIKE ?),
        ["tom", "alice", 1, "tom%"]
      }, adapter.select_sql)

      @builder.unscope!(:where)
      @builder.where!(name: "tom", group_id: 1)

      assert_sql({
        %(SELECT * FROM `users` WHERE `name` = ? AND `group_id` = ?), ["tom", 1]
      }, adapter.select_sql)
    end

    def test_select_order
      @builder.order!(:name)
      assert_sql %(SELECT * FROM `users` ORDER BY `name` ASC), adapter.select_sql

      @builder.unscope!(:order)
      @builder.order!(group_id: :desc, name: :asc)
      assert_sql %(SELECT * FROM `users` ORDER BY `group_id` DESC, `name` ASC), adapter.select_sql

      @builder.unscope!(:order)
      @builder.order!("name DESC NULLS LAST")
      assert_sql %(SELECT * FROM `users` ORDER BY name DESC NULLS LAST), adapter.select_sql
    end

    def test_select_reorder
      @builder.reorder!(:name)
      assert_sql %(SELECT * FROM `users` ORDER BY `name` ASC), adapter.select_sql

      @builder.reorder!(name: :desc)
      assert_sql %(SELECT * FROM `users` ORDER BY `name` DESC), adapter.select_sql

      @builder.reorder!({ :name => :asc, :about => :desc })
      assert_sql %(SELECT * FROM `users` ORDER BY `name` ASC, `about` DESC), adapter.select_sql

      @builder.reorder!("name DESC NULLS FIRST")
      assert_sql %(SELECT * FROM `users` ORDER BY name DESC NULLS FIRST), adapter.select_sql
    end

    def test_select_limit_and_offset
      @builder.limit!(10)
      assert_sql %(SELECT * FROM `users` LIMIT 10), adapter.select_sql

      @builder.offset!(200)
      assert_sql %(SELECT * FROM `users` LIMIT 10 OFFSET 200), adapter.select_sql
    end

    def test_insert
      uuid = UUID.random

      assert_sql({
        %(INSERT INTO `users` (`uuid`) VALUES (?)), [uuid]
      }, adapter.insert_sql({ uuid: uuid }))

      assert_sql({
        %(INSERT INTO `users` (`name`, `about`) VALUES (?, ?)),
        ["julien", nil]
      }, adapter.insert_sql({ name: "julien", about: nil }))

      assert_sql({
        %(INSERT INTO `users` (`name`, `about`) VALUES (?, ?)),
        ["julien", ""]
      }, adapter.insert_sql({ :name => "julien", :about => "" }))
    end

    def test_udpate
      assert_sql({
        %(UPDATE `users` SET `name` = ?), ["alice"]
      }, adapter.update_sql({ name: "alice" }))
    end

    def test_udpate_where
      uuid = UUID.random
      @builder.where!(uuid: uuid)

      assert_sql({
        %(UPDATE `users` SET `name` = ?, `about` = ? WHERE `uuid` = ?), ["alice", nil, uuid]
      }, adapter.update_sql({ "name" => "alice", :about => nil }))
    end

    def test_delete
      assert_sql %(DELETE FROM `users`), adapter.delete_sql
    end

    def test_delete_where
      uuid = UUID.random
      @builder.where!(uuid: uuid)

      assert_sql({
        %(DELETE FROM `users` WHERE `uuid` = ?), [uuid]
      }, adapter.delete_sql)
    end
  end
end
