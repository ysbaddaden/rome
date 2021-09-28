require "../test_helper"

module Rome
  class Associations::HasOneTest < Minitest::Test
    include TransactionalTests

    def test_getter
      assert_equal Account, typeof(Supplier.new(id: 1).account)
    end

    def test_setter_for_new_record
      supplier = Supplier.new
      supplier.account = Account.new
      refute supplier.account.persisted?
    end

    def test_setter
      supplier = Supplier.create
      first, second = Account.new, Account.new

      supplier.account = first
      assert first.persisted?
      assert_equal supplier.id, first.supplier_id

      supplier.account = second
      assert first.persisted?
      assert_equal supplier.id, second.supplier_id
    end

    def test_setter_with_dependent_nullify
      supplier = SupplierDependentNullify.create
      first, second = Account.new, Account.new

      supplier.account = first
      supplier.account = second

      assert_nil first.reload.supplier_id?
      assert_equal supplier.id, second.supplier_id
      assert_equal supplier.id, second.reload.supplier_id
    end

    def test_setter_with_dependent_delete
      supplier = SupplierDependentDelete.create
      first, second = Account.new, Account.new

      supplier.account = first
      supplier.account = second

      refute first.deleted?
      assert_raises(RecordNotFound) { first.reload }
      assert_equal supplier.id, second.supplier_id
      assert_equal supplier.id, second.reload.supplier_id
    end

    def test_setter_with_dependent_destroy
      supplier = SupplierDependentDestroy.create
      first, second = Account.new, Account.new

      supplier.account = first
      supplier.account = second

      assert first.deleted?
      assert_raises(RecordNotFound) { first.reload }
      assert_equal supplier.id, second.supplier_id
      assert_equal supplier.id, second.reload.supplier_id
    end

    def test_build
      supplier = Supplier.new
      account = supplier.build_account
      assert_instance_of Account, account
      assert_same account, supplier.account
      refute account.persisted?
    end

    def test_create
      supplier = Supplier.create
      account = supplier.create_account
      assert_instance_of Account, account
      assert_same account, supplier.account
      assert account.persisted?
    end

    def test_autosave_nil
      supplier = Supplier.new(id: 1)

      account = supplier.build_account
      refute account.persisted?

      supplier.save
      assert account.persisted?
    end

    def test_autosave_true
      supplier = SupplierAutosave.create(id: 2)

      account = supplier.build_account
      refute account.persisted?

      supplier.save
      assert account.persisted?
    end

    def test_autosave_false
      supplier = SupplierNoAutosave.create(id: 3)

      account = supplier.build_account
      refute account.persisted?

      supplier.save
      refute account.persisted?
    end

    def test_dependent_nil
      supplier = Supplier.create
      account = supplier.create_account
      supplier.destroy
      assert account.reload
    end

    def test_dependent_delete
      supplier = SupplierDependentDelete.create
      account = supplier.create_account
      supplier.destroy
      refute supplier.account.deleted?
      assert_raises(RecordNotFound) { account.reload }
    end

    def test_dependent_destroy
      supplier = SupplierDependentDestroy.create
      account = supplier.create_account
      supplier.destroy
      assert supplier.account.deleted?
      assert_raises(RecordNotFound) { account.reload }
    end

    def test_dependent_nullify
      supplier = SupplierDependentNullify.create
      account = supplier.create_account
      supplier.destroy
      assert_nil account.reload.supplier_id?
    end
  end
end
