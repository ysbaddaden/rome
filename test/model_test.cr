require "./test_helper"

module Rome
  class ModelTest < Minitest::Test
    class Foo < Model
      self.table_name = "foo"

      columns(
        id: {type: Int32, primary: true},
      )
    end

    class Bar < Model
      columns(
        uuid: {type: UUID, primary: true},
      )
    end

    class Qux < Model
      self.table_name = "qux"

      columns(
        id:    {type: Int32, primary: true},
        name:  {type: String},
        about: {type: String, nilable: true},
      )
    end

    def test_table_name
      assert_equal "foo", Foo.table_name
      assert_equal "bars", Bar.table_name
      assert_equal "qux", Qux.table_name
    end

    def test_primary_key
      assert_equal :id, Foo.primary_key
      assert_equal :uuid, Bar.primary_key
      assert_equal :id, Qux.primary_key
    end

    def test_id
      bar = Bar.new(uuid: UUID.random)
      assert_equal bar.uuid, bar.id
      assert_raises { Bar.new.id }
    end

    def test_id?
      bar = Bar.new(uuid: UUID.random)
      assert_equal bar.uuid, bar.id?
      assert_nil Bar.new.id?
    end

    def test_initializers
      qux = Qux.new
      assert_nil qux.id?
      assert_nil qux.name?
      assert_nil qux.about?

      qux = Qux.new(id: 1)
      assert_equal 1, qux.id?
      assert_nil qux.name?
      assert_nil qux.about?

      qux = Qux.new(id: 1, about: "description")
      assert_equal 1, qux.id?
      assert_nil qux.name?
      assert_equal "description", qux.about?
    end

    def test_getters_with_missing_attributes
      qux = Qux.new

      assert_raises(MissingAttribute) { qux.id }
      assert_nil qux.id?

      assert_raises(MissingAttribute) { qux.name }
      assert_nil qux.name?

      assert_nil qux.about
      assert_nil qux.about?
    end

    def test_getters_with_attributes
      qux = Qux.new(id: 1, name: "N", about: "A")
      assert_equal 1, qux.id
      assert_equal 1, qux.id?

      assert_equal "N", qux.name
      assert_equal "N", qux.name?

      assert_equal "A", qux.about
      assert_equal "A", qux.about?
    end

    def test_accessors_with_missing_attributes
      qux = Qux.new

      assert_raises(MissingAttribute) { qux[:id] }
      assert_raises(MissingAttribute) { qux["id"] }
      assert_nil qux[:id]?
      assert_nil qux["id"]?

      assert_raises(MissingAttribute) { qux[:name] }
      assert_raises(MissingAttribute) { qux["name"] }
      assert_nil qux[:name]?
      assert_nil qux["name"]?

      assert_nil qux[:about]
      assert_nil qux["about"]
      assert_nil qux[:about]?
      assert_nil qux["about"]?

      assert_raises(MissingAttribute) { qux["extra"] }
      assert_nil qux["extra"]?
    end

    def test_accessors_with_attributes
      qux = Qux.new(id: 1, name: "N", about: "A")
      qux.extra_attributes["extra"] = "all"

      assert_equal 1, qux[:id]
      assert_equal 1, qux["id"]
      assert_equal 1, qux[:id]?
      assert_equal 1, qux["id"]?

      assert_equal "N", qux[:name]
      assert_equal "N", qux["name"]
      assert_equal "N", qux[:name]?
      assert_equal "N", qux["name"]?

      assert_equal "A", qux[:about]
      assert_equal "A", qux["about"]
      assert_equal "A", qux[:about]?
      assert_equal "A", qux["about"]?

      assert_equal "all", qux["extra"]
      assert_equal "all", qux["extra"]?
    end

    def test_changed?
      qux = Qux.new
      refute qux.changed?
      refute qux.id_changed?
      refute qux.name_changed?

      qux.name = "ABC"
      assert qux.changed?
      refute qux.id_changed?
      assert qux.name_changed?

      qux.changes_applied
      refute qux.changed?
      refute qux.name_changed?

      qux.name = "ABC"
      refute qux.changed?
      refute qux.name_changed?
    end

    def test_dirty_attributes
      qux = Qux.new(name: "ABC")
      assert_nil qux.id_was
      assert_nil qux.name_was
      assert_equal({nil, nil}, qux.id_change)
      assert_equal({nil, "ABC"}, qux.name_change)

      qux.name = "DEF"
      assert_nil qux.id_was
      assert_equal "ABC", qux.name_was
      assert_equal({"ABC", "DEF"}, qux.name_change)

      qux.name = "GHI"
      assert_equal "ABC", qux.name_was
      assert_equal({"ABC", "GHI"}, qux.name_change)
    end

    def test_will_change!
      qux = Qux.new(name: "A")
      refute qux.changed?
      refute qux.id_changed?
      refute qux.name_changed?

      qux.name_will_change!
      assert qux.changed?
      refute qux.id_changed?
      assert qux.name_changed?
      assert_equal "A", qux.name_was
    end

    def test_restore_attributes
      qux = Qux.new(id: 1, name: "N", about: "A")
      qux.attributes = {id: 2, name: "M", about: "B"}

      qux.restore_attributes
      refute qux.changed?
      assert_equal 1, qux.id
      assert_equal "N", qux.name
      assert_equal "A", qux.about
    end

    def test_changes_applied
      qux = Qux.new(id: 1, name: "ABC", about: "foo")
      qux.attributes = {id: 2, name: "DEF", about: "bar"}
      assert qux.changed?

      qux.changes_applied
      refute qux.changed?

      assert_nil qux.id_was
      assert_nil qux.name_was
      assert_nil qux.about_was

      assert_equal 2, qux.id
      assert_equal "DEF", qux.name
      assert_equal "bar", qux.about
    end

    def test_clear_changes_information
      qux = Qux.new(id: 1, name: "ABC", about: "foo")
      qux.attributes = {id: 2, name: "DEF", about: "bar"}
      assert qux.changed?

      qux.clear_changes_information
      refute qux.changed?

      assert_equal 2, qux.id
      assert_equal "DEF", qux.name
      assert_equal "bar", qux.about

      assert_nil qux.id_was
      assert_nil qux.name_was
      assert_nil qux.about_was
    end

    def test_assign_attributes
      qux = Qux.new(name: "A")

      qux.attributes = {id: 123, name: "ABC"}
      assert_equal 123, qux.id
      assert_equal "ABC", qux.name

      qux.attributes = {id: 456}
      assert_equal 456, qux.id
      assert_equal "ABC", qux.name
    end

    def test_attributes_for_create
      assert_raises(MissingAttribute) { Qux.new.attributes_for_create }
      assert_equal({
        :id => nil,
        :name => "A",
        :about => nil,
      }, Qux.new(name: "A").attributes_for_create)
    end

    def test_attributes_for_update
      qux = Qux.new(id: 1, name: "B")
      qux.new_record = false

      assert_nil qux.attributes_for_update

      qux.name = "C"
      assert_equal({ :name => "C" }, qux.attributes_for_update)

      qux.about = "description"
      assert_equal({ :name => "C", :about => "description" }, qux.attributes_for_update)
    end

    def test_to_h
      assert_equal({ "id" => nil }, Foo.new.to_h)
      assert_equal({ "id" => 1 }, Foo.new(id: 1).to_h)

      uuid = UUID.random
      assert_equal({ "uuid" => nil }, Bar.new.to_h)
      assert_equal({ "uuid" => uuid }, Bar.new(uuid: uuid).to_h)

      assert_equal({
        "id" => nil,
        "name" => "A",
        "about" => nil
      }, Qux.new(name: "A").to_h)

      assert_equal({
        "id" => 2,
        "name" => "B",
        "about" => "C"
      }, Qux.new(name: "B", about: "C", id: 2).to_h)
    end

    def test_from_json
      foo = Foo.from_json(%({"id":1234}))
      assert_equal 1234, foo.id

      bar = Bar.from_json(%({"uuid":"de7c018a-122f-4bab-ac7f-ee2d3e7555d4"}))
      assert_equal UUID.new("de7c018a-122f-4bab-ac7f-ee2d3e7555d4"), bar.uuid

      qux = Qux.from_json(%({"id":12}))
      assert_equal 12, qux.id
      assert_nil qux.name?
      assert_nil qux.about

      qux = Qux.from_json <<-JSON
      {
        "id": 123,
        "name": "QUX",
        "about": "description"
      }
      JSON
      assert_equal 123, qux.id
      assert_equal "QUX", qux.name
      assert_equal "description", qux.about
    end

    def test_to_json
      qux = Qux.new(name: "B", about: "C", id: 2)

      assert_equal %({"id":2,"name":"B","about":"C"}), qux.to_json
      assert_equal <<-JSON, qux.to_json(indent: 2)
      {
        "id": 2,
        "name": "B",
        "about": "C"
      }
      JSON
    end
  end
end
