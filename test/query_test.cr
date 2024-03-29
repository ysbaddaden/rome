require "./test_helper"

module Rome
  class QueryTest < Minitest::Test
    @@created_groups = false
    @@group : Group?

    def group_id
      @@group.not_nil!.id
    end

    def setup
      return if @@group
      @@group = group = Group.create(name: "Group X")

      2.times do |index|
        User.create(uuid: UUID.random, group_id: group.id, name: "User X-#{index}")
      end
    end

    def test_each_iterator
      User.all.each { |record| assert_instance_of User, record }
    end

    def test_each_iterator
      users = User.all

      iterator = users.each
      assert_equal Iterator::Stop | User, typeof(iterator.next)

      until (value = iterator.next).is_a?(Iterator::Stop)
        assert_instance_of User, value
      end
    end

    def test_each_iterator_with_cache
      users = User.all
      users.to_a

      iterator = users.each
      assert_equal Iterator::Stop | User, typeof(iterator.next)

      until (value = iterator.next).is_a?(Iterator::Stop)
        assert_instance_of User, value
      end
    end

    def test_all
      assert_instance_of Collection(User), User.all
      assert_instance_of Collection(Group), Group.all

      assert_instance_of Array(User), User.all.to_a
      assert_instance_of Array(Group), Group.all.to_a
    end

    def test_none
      assert_equal Collection(User), typeof(User.none)
      assert_equal [] of User, User.none.to_a

      assert_equal Collection(Group), typeof(Group.none)
      assert_equal [] of Group, Group.none.to_a

      assert_equal Collection(User), typeof(User.select("*").none)
      assert_equal [] of User, User.select("*").none.to_a

      assert_equal Collection(Group), typeof(Group.select("*").none)
      assert_equal [] of Group, Group.select("*").none.to_a

      assert_nil Group.none.find?(group_id)
      assert_nil Group.none.find_by?(id: group_id)
      refute Group.none.exists?(group_id)

      assert_equal 0, Group.none.count
      assert_equal 0, Group.none.sum("LENGTH(name)")
      assert_equal 0, Group.none.average("LENGTH(name)")
      assert_nil Group.none.minimum("name")
      assert_nil Group.none.maximum("name")
    end

    def test_ids
      assert_equal Array(UUID), typeof(User.ids)
      assert_equal Array(Int32), typeof(Group.ids)
      assert_instance_of Array(UUID), User.ids
      assert_instance_of Array(Int32), Group.ids
    end

    def test_find
      assert_equal User, typeof(User.find(UUID.random))
      assert_equal Group, typeof(Group.find(group_id))

      assert_raises(RecordNotFound) { User.find(UUID.random) }
      assert_instance_of Group, Group.find(group_id)
    end

    def test_find?
      assert_equal User?, typeof(User.find?(UUID.random))
      assert_equal Group?, typeof(Group.find?(group_id))

      assert_nil User.find?(UUID.random)
      assert_instance_of Group, Group.find?(group_id)
    end

    def test_take
      assert_instance_of User, User.take
      assert_instance_of Group, Group.take
      assert_raises(RecordNotFound) { User.where(uuid: UUID.random).take }
    end

    def test_take?
      assert_instance_of User, User.take?
      assert_instance_of Group, Group.take?
      assert_nil User.where(uuid: UUID.random).take?
    end

    def test_find_by
      assert_equal User, typeof(User.find_by(uuid: UUID.random))
      assert_equal Group, typeof(Group.find_by(id: group_id))

      assert_raises(RecordNotFound) { User.find_by(uuid: UUID.random) }
      assert_instance_of Group, Group.find_by(id: group_id)
    end

    def test_find_by?
      assert_equal User?, typeof(User.find_by?(uuid: UUID.random))
      assert_equal Group?, typeof(Group.find_by?(id: group_id))

      assert_nil User.find_by?(uuid: UUID.random)
      assert_instance_of Group, Group.find_by?(id: group_id)
    end

    def test_find_all_by_sql
      assert_equal Array(User), typeof(User.find_all_by_sql("SELECT * FROM users"))
      assert_equal Array(Group), typeof(Group.find_all_by_sql("SELECT * FROM groups"))

      assert_instance_of Array(User), User.find_all_by_sql("SELECT * FROM users")
      assert_instance_of Array(Group), Group.find_all_by_sql("SELECT * FROM groups")
    end

    def test_find_one_by_sql
      case URI.parse(Rome.database_url).scheme
      when "postgres"
        user_sql = "SELECT * FROM users WHERE uuid = $1 LIMIT 1"
        group_sql = "SELECT * FROM groups WHERE id = $1 LIMIT 1"
      else
        user_sql = "SELECT * FROM users WHERE uuid = ? LIMIT 1"
        group_sql = "SELECT * FROM groups WHERE id = ? LIMIT 1"
      end

      assert_equal User, typeof(User.find_one_by_sql("SELECT * FROM users LIMIT 1"))
      assert_equal Group, typeof(Group.find_one_by_sql("SELECT * FROM groups LIMIT 1"))

      assert_instance_of User, User.find_one_by_sql("SELECT * FROM users LIMIT 1")
      assert_instance_of Group, Group.find_one_by_sql("SELECT * FROM groups LIMIT 1")

      assert_raises(RecordNotFound) { User.find_one_by_sql(user_sql, UUID.random) }
      assert_raises(RecordNotFound) { Group.find_one_by_sql(group_sql, Int32::MAX - 10) }
    end

    def test_find_one_by_sql?
      case URI.parse(Rome.database_url).scheme
      when "postgres"
        user_sql = "SELECT * FROM users WHERE uuid = $1 LIMIT 1"
        group_sql = "SELECT * FROM groups WHERE id = $1 LIMIT 1"
      else
        user_sql = "SELECT * FROM users WHERE uuid = ? LIMIT 1"
        group_sql = "SELECT * FROM groups WHERE id = ? LIMIT 1"
      end

      assert_equal User?, typeof(User.find_one_by_sql?(user_sql, UUID.random))
      assert_equal Group?, typeof(Group.find_one_by_sql?(group_sql, 1))

      assert_instance_of User, User.find_one_by_sql?("SELECT * FROM users LIMIT 1")
      assert_instance_of Group, Group.find_one_by_sql?("SELECT * FROM groups LIMIT 1")

      assert_nil User.find_one_by_sql?(user_sql, UUID.random)
      assert_nil Group.find_one_by_sql?(group_sql, Int32::MAX)
    end

    def test_first
      assert_equal Group, typeof(Group.first)
      assert_equal User, typeof(User.where(group_id: group_id).order(:name).first)

      assert_instance_of Group, Group.first
      assert_instance_of User, User.where(group_id: group_id).order(:name).first
    end

    def test_first?
      assert_equal Group?, typeof(Group.first?)
      assert_equal User?, typeof(User.where(group_id: group_id).order(:name).first?)

      assert_instance_of Group, Group.first?
      assert_instance_of User, User.where(group_id: group_id).order(:name).first?
    end

    def test_last
      assert_equal Group, typeof(Group.last)
      assert_equal User, typeof(User.where(group_id: group_id).order(:name).last)

      assert_instance_of Group, Group.last
      assert_instance_of User, User.where(group_id: group_id).order(:name).last
      assert_instance_of User, User.where(group_id: group_id).order("name ASC, group_id DESC").last
    end

    def test_last?
      assert_equal Group?, typeof(Group.last?)
      assert_equal User?, typeof(User.where(group_id: group_id).order(:name).last?)

      assert_instance_of Group, Group.last?
      assert_instance_of User, User.where(group_id: group_id).order(:name).last?
      assert_instance_of User, User.where(group_id: group_id).order("name DESC, group_id ASC").last
    end

    def test_exists?
      assert User.where(group_id: group_id).exists?
      assert Group.exists?(group_id)
    end

    def test_where
      users = User.where("name LIKE ?", "X-%").where("group_id BETWEEN ? AND ?", -1, 200)
      assert_instance_of Array(User), users.to_a
    end

    def test_where_regex
      users = User.where(group_id: group_id)

      assert_equal 2, users.where(name: /X-/).count
      assert_equal 0, users.where(name: /x-/).count
      refute_equal 2, users.where_not(name: /X-/).count

      # can't pass the ignore case to SQLite3::REGEXP_FN
      unless Rome.adapter_class == Rome::Adapter::SQLite3
        assert_equal 2, users.where(name: /x-/i).count
        assert_equal 0, users.where_not(name: /x-/i).count
      end
    end

    def test_order
      users = User.order(:name, "group_id DESC")
      assert_instance_of Array(User), users.to_a
    end

    def test_pluck
      User.pluck(:uuid).each do |uuid|
        if Rome.adapter_class == Rome::Adapter::SQLite3
          assert_instance_of Bytes, uuid
        else
          assert_instance_of UUID|String, uuid
        end
      end
      User.pluck("LENGTH(name)").each { |len| assert_instance_of Int, len }
    end

    def test_count
      total = User.count
      assert_instance_of Int64, total

      distinct1 = User.distinct.count(:group_id)
      assert_instance_of Int64, distinct1

      distinct2 = User.count(:group_id, distinct: true)
      assert_instance_of Int64, distinct2

      assert_equal total, User.count(:group_id)
      assert distinct1 < total
      assert_equal distinct1, distinct2
    end

    def test_average
      assert_instance_of Float64, User.average(:group_id)
      assert_instance_of Float64, User.average("LENGTH(name)")
    end

    def test_sum
      assert_instance_of Int64, User.sum(:group_id)
      assert_instance_of Int64, User.sum("LENGTH(name)")
    end

    def test_minimum
      assert_instance_of Int, User.minimum(:group_id)
      assert_instance_of String, User.minimum(:name)
      assert_instance_of Int, User.minimum("LENGTH(name)")
    end

    def test_maximum
      assert_instance_of Int, User.maximum(:group_id)
      assert_instance_of String, User.maximum(:name)
      assert_instance_of Int, User.maximum("LENGTH(name)")
    end
  end
end
