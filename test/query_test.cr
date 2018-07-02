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

    def test_all
      assert_instance_of Array(User), User.all
      assert_instance_of Array(Group), Group.all
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
    end

    def test_last?
      assert_equal Group?, typeof(Group.last?)
      assert_equal User?, typeof(User.where(group_id: group_id).order(:name).last?)

      assert_instance_of Group, Group.last?
      assert_instance_of User, User.where(group_id: group_id).order(:name).last?
    end

    def test_exists?
      assert User.where(group_id: group_id).exists?
      assert Group.exists?(group_id)
    end

    def test_where
      users = User.where("name LIKE ?", "X-%").where("group_id BETWEEN ? AND ?", -1, 200)
      assert_instance_of Array(User), users.all
    end

    def test_order
      users = User.order(:name, "group_id DESC")
      assert_instance_of Array(User), users.all
    end
  end
end
