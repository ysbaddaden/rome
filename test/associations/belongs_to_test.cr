require "../test_helper"

module Rome
  class Associations::BelongsToTest < Minitest::Test
    include TransactionalTests

    def test
      assert_equal Author, typeof(Book.new(id: 1, author_id: 1, name: "").author)
      assert_equal Supplier, typeof(Account.new(id: 1, supplier_id: 1).supplier)
    end

    def test_setter_for_new_record
      book = Book.new
      book.author = Author.new
      assert_nil book.author_id?
    end

    def test_setter
      author = Author.create(name: "Adams")
      book = Book.new(name: "H2G2")
      book.author = author
      assert_equal author.id, book.author_id?
    end

    def test_build
      book = Book.new
      author = book.build_author
      assert_instance_of Author, author
      assert_same author, book.author
      refute author.persisted?
    end

    def test_create
      book = Book.new
      author = book.create_author(name: "Neil")
      assert_instance_of Author, author
      assert_same author, book.author
      assert author.persisted?
    end

    def test_autosave_nil
      book = Book.new(name: "Odd and the Frost Giants")

      # saves new record:
      author = book.build_author(name: "Terry")
      refute author.persisted?

      book.save
      assert author.persisted?

      # won't save previously persisted record:
      author.name = "Another Terry"
      book.save
      assert author.changed?
    end

    def test_autosave_true
      book = BookAutosave.new(name: "Starship Titanic")

      # saves new record:
      author = book.build_author(name: "Douglas Adams")
      refute author.persisted?

      book.save
      assert author.persisted?

      # saves previously persisted record:
      author.name = "Another Douglas"
      book.save
      refute author.changed?
    end

    def test_autosave_false
      book = BookNoAutosave.new(name: "Discworld")

      # never saves record
      author = book.build_author(name: "Terry")
      refute author.persisted?

      # can't save supplier: missing account_id attribute
      ex = assert_raises(Rome::MissingAttribute) { book.save }
      assert_match "author_id is missing", ex.message
      refute book.persisted?
      refute author.persisted?
    end

    def test_dependent_nil
      account = Account.new
      account.supplier = Supplier.create
      account.save

      account.destroy
      refute account.supplier.deleted?
      assert account.supplier.reload
    end

    def test_dependent_delete
      account = AccountDependentDelete.new
      account.supplier = Supplier.create
      account.save

      account.destroy
      refute account.supplier.deleted?
      assert_raises(RecordNotFound) { account.supplier.reload }
    end

    def test_dependent_destroy
      account = AccountDependentDestroy.new
      account.supplier = Supplier.create
      account.save

      account.destroy
      assert account.supplier.deleted?
      assert_raises(RecordNotFound) { account.supplier.reload }
    end
  end
end
