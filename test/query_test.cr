require "./test_helper"

module Rome
  class QueryTest < Minitest::Test
    def test_all
      assert_equal Array(User), typeof(User.all)
      assert_equal Array(Group), typeof(Group.all)
    end

    def test_find
      assert_equal User, typeof(User.find(UUID.random))
      assert_equal Group, typeof(Group.find(1))
    end

    def test_find?
      assert_equal User?, typeof(User.find?(UUID.random))
      assert_equal Group?, typeof(Group.find?(1))
    end

    def test_find_by
      assert_equal User, typeof(User.find_by(uuid: UUID.random))
      assert_equal Group, typeof(Group.find_by(id: 1))
    end

    def test_find_by?
      assert_equal User?, typeof(User.find_by?(uuid: UUID.random))
      assert_equal Group?, typeof(Group.find_by?(id: 1))
    end
  end
end
