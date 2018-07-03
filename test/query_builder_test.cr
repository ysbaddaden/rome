require "./test_helper"

module Rome
  class QueryBuilderTest < Minitest::Test
    def test_select
      b1 = QueryBuilder.new("foos")
      b2 = b1.select(:id).select(:name, "1 AS one")

      assert_nil b1.selects
      assert_equal [:id, :name, "1 AS one"], b2.selects
    end

    def test_select!
      b = QueryBuilder.new("foos")
      b.select!(:id).select!(:name, :value, "1 AS one")
      assert_equal [:id, :name, :value, "1 AS one"], b.selects
    end

    def test_distinct
      b1 = QueryBuilder.new("foos")
      b2 = b1.distinct

      refute b1.distinct?
      assert b2.distinct?
    end

    def test_distinct!
      b = QueryBuilder.new("foos")
      refute b.distinct?

      b.distinct!
      assert b.distinct?
    end

    def test_limit
      b1 = QueryBuilder.new("foos")
      b2 = b1.limit(50)

      assert_nil b1.limit
      assert_equal 50, b2.limit
    end

    def test_limit!
      b = QueryBuilder.new("foos")
      b.limit!(50)
      assert_equal 50, b.limit
    end

    def test_offset
      b1 = QueryBuilder.new("foos")
      b2 = b1.offset(200)

      assert_nil b1.offset
      assert_equal 200, b2.offset
    end

    def test_offset!
      b = QueryBuilder.new("foos")
      b.offset!(200)
      assert_equal 200, b.offset
    end

    def test_where
      b1 = QueryBuilder.new("foos")

      b2 = b1.where({ :id => 1 })
      b3 = b2.where({ name: "something" })

      uuid = UUID.random
      b4 = b2.where(group_id: uuid, minimum: 123.456)

      b5 = b2.where("key LIKE ?", "test%")
        .where("value > ? AND value < ?", 10, 20)

      assert_nil b1.conditions
      assert_equal [
        QueryBuilder::Condition.new(:id, 1),
      ], b2.conditions

      assert_equal [
        QueryBuilder::Condition.new(:id, 1),
        QueryBuilder::Condition.new(:name, "something"),
      ], b3.conditions

      assert_equal [
        QueryBuilder::Condition.new(:id, 1),
        QueryBuilder::Condition.new(:group_id, uuid),
        QueryBuilder::Condition.new(:minimum, 123.456),
      ], b4.conditions

      assert_equal [
        QueryBuilder::Condition.new(:id, 1),
        QueryBuilder::RawCondition.new("key LIKE ?", ["test%"] of Value),
        QueryBuilder::RawCondition.new("value > ? AND value < ?", [10, 20] of Value),
      ], b5.conditions
    end

    def test_where_in
      b1 = QueryBuilder.new("foos")
      b2 = b1.where(id: [1, 3, 4])

      assert_nil b1.conditions
      assert_equal [
        QueryBuilder::Condition.new(:id, [1, 3, 4] of Value),
      ], b2.conditions
    end

    def test_where_not
      b1 = QueryBuilder.new("foos")
      b2 = b1.where_not(id: 12)
      b3 = b2.where_not("id > ?", 12345).where("name IS NOT NULL")

      assert_nil b1.conditions

      assert_equal [
        QueryBuilder::Condition.new(:id, 12, not: true),
      ], b2.conditions

      assert_equal [
        QueryBuilder::Condition.new(:id, 12, not: true),
        QueryBuilder::RawCondition.new("id > ?", [12345] of Value, not: true),
        QueryBuilder::RawCondition.new("name IS NOT NULL", nil),
      ], b3.conditions
    end

    def test_where_not!
      b = QueryBuilder.new("foos")
      b.where_not!(id: 12)
      b.where_not!("id > ?", 12345)
      b.where!("name IS NOT NULL")

      assert_equal [
        QueryBuilder::Condition.new(:id, 12, not: true),
        QueryBuilder::RawCondition.new("id > ?", [12345] of Value, not: true),
        QueryBuilder::RawCondition.new("name IS NOT NULL", nil),
      ], b.conditions
    end

    def test_where!
      b = QueryBuilder.new("foos")
      b.where!({ :id => 1 })
        .where!({ name: "something" })
        .where!(minimum: 123.4)
        .where!("key LIKE ?", "test%")
        .where!("value > ? AND value < ?", 10, 20)
      assert_equal [
        QueryBuilder::Condition.new(:id, 1),
        QueryBuilder::Condition.new(:name, "something"),
        QueryBuilder::Condition.new(:minimum, 123.4),
        QueryBuilder::RawCondition.new("key LIKE ?", ["test%"] of Value),
        QueryBuilder::RawCondition.new("value > ? AND value < ?", [10, 20] of Value),
      ], b.conditions
    end

    def test_order
      b1 = QueryBuilder.new("foos")
      b2 = b1.order(:id)
      b3 = b2.order(:name, :value)
        .order(minimum: :desc)
        .order({ :maximum => :asc })

      assert_nil b1.orders
      assert_equal [{:id, :asc}], b2.orders
      assert_equal [
        {:id, :asc},
        {:name, :asc},
        {:value, :asc},
        {:minimum, :desc},
        {:maximum, :asc},
      ], b3.orders
    end

    def test_order!
      b = QueryBuilder.new("foos")
      b.order!(:id)
        .order!(:name, :value)
        .order!(minimum: :desc)
        .order!({ :maximum => :asc })

      assert_equal [
        {:id, :asc},
        {:name, :asc},
        {:value, :asc},
        {:minimum, :desc},
        {:maximum, :asc},
      ], b.orders
    end

    def test_reorder
      b1 = QueryBuilder.new("foos").order(:id, :name)
      b2 = b1.reorder(:value, :minimum)
      b3 = b2.reorder(:id)
      b4 = b3.reorder(id: :desc)
      b5 = b3.reorder({ :id => :desc })

      assert_equal [{:value, :asc}, {:minimum, :asc}], b2.orders
      assert_equal [{:id, :asc}], b3.orders
      assert_equal [{:id, :desc}], b4.orders
      assert_equal [{:id, :desc}], b5.orders
    end

    def test_reorder!
      b = QueryBuilder.new("foos").order(:id, :name)

      b.reorder!(:value, :minimum)
      assert_equal [{:value, :asc}, {:minimum, :asc}], b.orders

      b.reorder!(:id)
      assert_equal [{:id, :asc}], b.orders

      b.reorder!(id: :desc)
      assert_equal [{:id, :desc}], b.orders

      b.reorder!({ :value => :asc })
      assert_equal [{:value, :asc}], b.orders
    end

    def test_unscope
      b = QueryBuilder.new("foos")
        .select(:id, :group_id)
        .where(group_id: 1)
        .order(:id)
        .limit(10)
        .offset(200)

      b1 = b.unscope(:select)
      b2 = b.unscope(:where)
      b3 = b.unscope(:order)
      b4 = b.unscope(:limit)
      b5 = b.unscope(:offset)

      refute_nil b.selects?
      refute_nil b.conditions?
      refute_nil b.orders?
      refute_nil b.limit
      refute_nil b.offset

      assert_nil b1.selects?
      refute_nil b1.conditions?
      refute_nil b1.orders?
      refute_nil b1.limit
      refute_nil b1.offset

      refute_nil b2.selects?
      assert_nil b2.conditions?
      refute_nil b2.orders?
      refute_nil b2.limit
      refute_nil b2.offset

      refute_nil b3.selects?
      refute_nil b3.conditions?
      assert_nil b3.orders?
      refute_nil b3.limit
      refute_nil b3.offset

      refute_nil b4.selects?
      refute_nil b4.conditions?
      refute_nil b4.orders?
      assert_nil b4.limit
      refute_nil b4.offset

      refute_nil b5.selects?
      refute_nil b5.conditions?
      refute_nil b5.orders?
      refute_nil b5.limit
      assert_nil b5.offset
    end

    def test_unscope!
      b = QueryBuilder.new("foos")
        .select!(:id, :group_id)
        .where!(group_id: 1)
        .order!(:id)
        .limit!(10)
        .offset!(200)

      b.unscope!(:select)
      assert_nil b.selects?
      refute_nil b.conditions?
      refute_nil b.orders?
      refute_nil b.limit
      refute_nil b.offset

      b.unscope!(:where)
      assert_nil b.conditions?
      refute_nil b.orders?
      refute_nil b.limit
      refute_nil b.offset

      b.unscope!(:order)
      assert_nil b.orders?
      refute_nil b.limit
      refute_nil b.offset

      b.unscope!(:limit)
      assert_nil b.limit
      refute_nil b.offset

      b.unscope!(:offset)
      assert_nil b.offset
    end
  end
end
