require "./test_helper"

module Rome
  class ConnectionTest < Minitest::Test
    def test_methods
      assert_instance_of DB::Database, Rome.pool
      typeof(Rome.adapter_class)
    end

    def test_using_connection
      Rome.with_connection do |db|
        Rome.with_connection do |db2|
          assert_same db, db2
        end

        Rome.connection do |db3|
          assert_same db, db3
        end
      end
    end

    def test_connection
      Rome.connection do |db1|
        Rome.connection do |db2|
          refute_same db1, db2
        end
      end
    end

    def test_transaction
      Rome.transaction do |tx|
        assert_instance_of DB::Transaction, tx
      end
    end

    def test_transaction_commit
      user = group = nil

      Rome.transaction do
        group = Group.create(name: "A")
        user = User.create(uuid: UUID.random, name: "B", group_id: group.id)
      end

      assert Group.exists?(group.not_nil!.id)
      assert User.exists?(user.not_nil!.uuid)
    end

    def test_transaction_rollback
      user = group = nil

      assert_raises(MissingAttribute) do
        Rome.transaction do
          group = Group.create(name: "B")
          user = User.create(name: "C") # error
        end
      end

      refute Group.exists?(group.not_nil!.id)
      refute user
    end

    def test_nested_transactions
      user1 = user2 = user3 = group = nil

      Rome.transaction do
        group = Group.create(name: "B")

        assert_raises(MissingAttribute) do
          Rome.transaction do
            user1 = User.create(uuid: UUID.random, name: "C", group_id: group.id)
            user2 = User.create(name: "C") # error
          end
        end

        Rome.transaction do
          user3 = User.create(uuid: UUID.random, name: "D", group_id: group.id)
        end
      end

      assert Group.exists?(group.not_nil!.id)
      refute User.exists?(user1.not_nil!.uuid)
      refute user2
      assert User.exists?(user3.not_nil!.uuid)
    end
  end
end
