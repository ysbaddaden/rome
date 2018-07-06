require "./test_helper"

module Rome
  class PersistenceTest < Minitest::Test
    def teardown
      Rome.connection do |db|
        db.exec("TRUNCATE groups;")
        db.exec("TRUNCATE users;")
      end
    end

    def test_create
      assert_equal Group, typeof(Group.create(id: 0, name: "PLANET EXPRESS"))
      assert_equal Group, typeof(Group.create(name: "PLANET EXPRESS", description: "The Worst Deliveries"))

      group = Group.create(id: 0, name: "PLANET EXPRESS")
      refute group.changed?
      assert_equal 0, group.id
      assert_equal "PLANET EXPRESS", group.name
      assert_nil group.description

      group = Group.create(name: "MOM CORP", description: "Best Cakes Ever")
      refute_nil group.id?
      assert_equal "MOM CORP", group.name
      assert_equal "Best Cakes Ever", group.description

      uuid = UUID.random
      user = User.create(uuid: uuid, group_id: group.id, name: "Fry")
      assert_equal uuid, user.uuid
      assert_equal "Fry", user.name
      assert_equal group.id, user.group_id
      refute_nil user.created_at
      refute_nil user.updated_at
    end

    def test_save
      # 1. create
      group = Group.new(name: "A")
      group.description = "D"

      group.save
      refute group.changed?
      refute_nil group.id?

      # 2. update
      group.name = "astronomy"
      group.description = "domine"
      group.save
      refute group.changed?

      group = Group.find(group.id)
      assert_equal "astronomy", group.name
      assert_equal "domine", group.description
    end

    def test_new_record?
      group = Group.new(name: "A")
      assert group.new_record?

      group.save
      refute group.new_record?

      group = Group.find(group.id)
      refute group.new_record?

      assert Group.all.none?(&.new_record?)
    end

    def test_persisted?
      group = Group.new(name: "A")
      refute group.persisted?

      group.save
      assert group.persisted?

      group = Group.find(group.id)
      assert group.persisted?

      assert Group.all.all?(&.persisted?)
    end

    def test_update
      group = Group.create(name: "A")

      group.update(name: "B", description: "a few words")
      assert_equal "B", group.name
      assert_equal "a few words", group.description
      refute group.changed?

      group = Group.find(group.id)
      assert_equal "B", group.name
      assert_equal "a few words", group.description
    end

    def test_delete
      group = Group.create(name: "A")
      group.delete
      assert group.deleted?
      refute group.persisted?
      refute group.new_record?
      refute Group.find?(group.id)
    end

    def test_reload
      group = Group.create(name: "test")
      Group.find(group.id).update(name: "reloaded")

      assert_equal "reloaded", group.reload.name
      assert_equal "reloaded", group.name
      refute group.new_record?
      assert group.persisted?
      refute group.changed?

      Group.find(group.id).delete
      assert_raises(RecordNotFound) { group.reload }
    end
  end
end
