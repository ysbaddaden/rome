require "./test_helper"

module Rome
  class AssociationsTest < Minitest::Test
    class AuthorAutosave < Rome::Model
      self.table_name = "authors"
      columns(
        id:   {type: Int32, primary_key: true},
        name: {type: String},
      )
      has_many :books, autosave: true, foreign_key: "author_id"
    end

    class AuthorNoAutosave < Rome::Model
      self.table_name = "authors"
      columns(
        id:   {type: Int32, primary_key: true},
        name: {type: String},
      )
      has_many :books, autosave: false, foreign_key: "author_id"
    end

    class BookAutosave < Rome::Model
      self.table_name = "books"
      columns(
        id:        {type: Int32, primary_key: true},
        author_id: {type: Int32},
        name:      {type: String},
      )
      belongs_to :author, autosave: true
    end

    class BookNoAutosave < Rome::Model
      self.table_name = "books"
      columns(
        id:        {type: Int32, primary_key: true},
        author_id: {type: Int32},
        name:      {type: String},
      )
      belongs_to :author, autosave: false
    end

    class SupplierAutosave < Rome::Model
      self.table_name = "suppliers"
      columns(id: {type: Int32, primary_key: true})
      has_one :account, autosave: true, foreign_key: "supplier_id"
    end

    class SupplierNoAutosave < Rome::Model
      self.table_name = "suppliers"
      columns(id: {type: Int32, primary_key: true})
      has_one :account, autosave: false, foreign_key: "supplier_id"
    end

    def test_belongs_to
      assert_equal Author, typeof(Book.new(id: 1, author_id: 1, name: "").author)
      assert_equal Supplier, typeof(Account.new(id: 1, supplier_id: 1).supplier)
    end

    def test_belongs_to_build
      book = Book.new
      author = book.build_author
      assert_instance_of Author, author
      assert_same author, book.author
    end

    def test_belongs_to_create
      skip
    end

    def test_belongs_to_create!
      skip
    end

    def test_belongs_to_autosave_nil
      skip
    end

    def test_belongs_to_autosave_true
      skip
    end

    def test_belongs_to_autosave_false
      skip
    end

    def test_has_one
      assert_equal Account, typeof(Supplier.new(id: 1).account)
    end

    def test_has_one_build
      supplier = Supplier.new
      account = supplier.build_account
      assert_instance_of Account, account
      assert_same account, supplier.account
    end

    def test_has_one_create
      skip
    end

    def test_has_one_create!
      skip
    end

    def test_has_one_autosave_nil
      supplier = Supplier.new(id: 1)

      account = supplier.build_account
      refute account.persisted?

      supplier.save
      assert account.persisted?
    end

    def test_has_one_autosave_true
      supplier = SupplierAutosave.create(id: 2)

      account = supplier.build_account
      refute account.persisted?

      supplier.save
      assert account.persisted?
    end

    def test_has_one_autosave_false
      supplier = SupplierNoAutosave.create(id: 3)

      account = supplier.build_account
      refute account.persisted?

      supplier.save
      refute account.persisted?
    end

    def test_has_many
      assert_equal Relation(Book), typeof(Author.new(id: 1, name: "").books)
      assert_raises(RecordNotSaved) { Author.new(name: "").books.to_a }
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

    def test_has_many_autosave_nil
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

    def test_has_many_autosave_true
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

    def test_has_many_autosave_false
      author = AuthorNoAutosave.new(name: "Neil")
      author.books.build(name: "Coraline")
      author.books.build(name: "Neverwhere")
      author.save

      assert author.persisted?
      refute author.books.any?(&.persisted?)
      assert_equal 0, author.books.reload.size
    end

    def test_save_associations
      typeof(Author.new(name: "").save_associations {})
      typeof(Book.new(name: "").save_associations {})
      typeof(Supplier.new.save_associations {})
      typeof(Account.new.save_associations {})
    end
  end
end
