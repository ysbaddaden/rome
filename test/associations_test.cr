require "./test_helper"

module Rome
  class AssociationsTest < Minitest::Test
    def test_belongs_to
      assert_equal Author, typeof(Book.new(id: 1, author_id: 1, name: "").author)
      assert_equal Supplier, typeof(Account.new(id: 1, supplier_id: 1).supplier)
    end

    def test_has_one
      assert_equal Account, typeof(Supplier.new(id: 1).account)
    end

    def test_has_many
      assert_equal Relation(Book), typeof(Author.new(id: 1, name: "").books)
      assert_raises(RecordNotSaved) { Author.new(name: "").books }
    end

    def test_has_many_build
      author = Author.create(name: "Neil")
      book = author.books.build(name: "Ocean")
      refute book.persisted?
      assert_nil book.id?
      assert_equal author.id, book.author_id?
    end

    def test_has_many_create
      author = Author.create(name: "Neil")
      book = author.books.create(name: "Ocean")
      assert book.persisted?
      assert book.id?
      assert_equal author.id, book.author_id?
    end

    def test_has_many_delete
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

    def test_save_associations
      typeof(Author.new(name: "").save_associations {})
      typeof(Book.new(name: "").save_associations {})
      typeof(Supplier.new.save_associations {})
      typeof(Account.new.save_associations {})
    end
  end
end
