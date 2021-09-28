require "../test_helper"

module Rome
  class Associations::HasManyTest < Minitest::Test
    include TransactionalTests

    def test_getter
      assert_equal Relation(Book), typeof(Author.new(id: 1, name: "").books)
      assert_raises(RecordNotSaved) { Author.new(name: "").books.to_a }
    end

    def test_build
      author = Author.create(name: "Neil")
      book = author.books.build(name: "Ocean")
      refute book.persisted?
      assert_nil book.id?
      assert_equal author.id, book.author_id?
    end

    def test_create
      author = Author.create(name: "Neil")
      book = author.books.create(name: "Ocean")
      assert book.persisted?
      assert book.id?
      assert_equal author.id, book.author_id?
    end

    def test_delete
      author = Author.create(name: "Neil")
      ocean = author.books.create(name: "The Ocean at the End of the Lane")
      coraline = author.books.create(name: "Coraline")
      neverwhere = author.books.create(name: "Neverwhere")

      # fill cache:
      author.books.to_a
      assert_equal 3, author.books.size

      # delete:
      author.books.delete(neverwhere, ocean)

      # removed from db:
      assert_equal [coraline.id], author.books.ids

      # removed from cache:
      assert_equal [coraline.id], author.books.map(&.id)
    end

    def test_autosave_nil
      author = Author.new(name: "Neil")
      neverwhere = author.books.build(name: "Neverwehre")
      neverwhere.name = "Neverwhere"

      author.save
      assert author.persisted?

      coraline = author.books.create(name: "Corailne")
      coraline.name = "Coraline"

      author.save

      assert coraline.changed?
      assert_equal "Corailne", coraline.reload.name

      refute neverwhere.changed?
      assert_equal "Neverwhere", neverwhere.reload.name
    end

    def test_autosave_true
      author = AuthorAutosave.new(name: "Neil")
      author.save
      assert author.persisted?

      coraline = author.books.create(name: "Corailne")
      coraline.name = "Coraline"

      neverwhere = author.books.build(name: "Neverwehre")
      neverwhere.name = "Neverwhere"

      author.save

      refute coraline.changed?
      assert_equal "Coraline", coraline.reload.name

      refute neverwhere.changed?
      assert_equal "Neverwhere", neverwhere.reload.name
    end

    def test_autosave_false
      author = AuthorNoAutosave.new(name: "Neil")
      author.books.build(name: "Coraline")
      author.books.build(name: "Neverwhere")
      author.save

      assert author.persisted?
      refute author.books.any?(&.persisted?)
      assert_equal 0, author.books.reload.size
    end

    def test_dependent_nil
      skip
    end

    def test_dependent_destroy
      skip
    end

    def test_dependent_delete_all
      skip
    end

    def test_dependent_nullify
      skip
    end

    def test_save_associations
      typeof(Author.new(name: "").save_associations {})
      typeof(Book.new(name: "").save_associations {})
      typeof(Supplier.new.save_associations {})
      typeof(Account.new.save_associations {})
    end
  end
end
