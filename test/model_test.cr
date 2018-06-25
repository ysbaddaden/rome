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

    def test_attributes
      assert_equal({id: nil}, Foo.new.attributes)
      assert_equal({id: 1}, Foo.new(id: 1).attributes)

      uuid = UUID.random
      assert_equal({uuid: nil}, Bar.new.attributes)
      assert_equal({uuid: uuid}, Bar.new(uuid: uuid).attributes)

      assert_equal({
        id: nil,
        name: "A",
        about: nil
      }, Qux.new(name: "A").attributes)

      assert_equal({
        id: 2,
        name: "B",
        about: "C"
      }, Qux.new(name: "B", about: "C", id: 2).attributes)
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
