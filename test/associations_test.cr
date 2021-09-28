require "./test_helper"

module Rome
  class AssociationsTest < Minitest::Test
    def test_save_associations
      typeof(Author.new(name: "").save_associations {})
      typeof(Book.new(name: "").save_associations {})
      typeof(Supplier.new.save_associations {})
      typeof(Account.new.save_associations {})
    end
  end
end
