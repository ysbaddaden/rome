module Rome
  abstract class Model
    # Creates a record in database with the specified attributes. For example:
    # ```
    # user = User.create(name: "julien", group_id: 2)
    # # => User(id: 1, name: "julien", group_id: 2)
    # ```
    #
    # Automatically fills the `created_at` and `updated_at` columns if they
    # exist and are `nil`.
    def self.create(**args) : self
      create new(**args)
    end

    protected def self.create(record : self) : self
      raise ReadOnlyRecord.new if record.deleted?

      if record.responds_to?(:created_at=)
        record.created_at ||= Time.utc
      end
      if record.responds_to?(:updated_at=)
        record.updated_at ||= Time.utc
      end

      attributes = record.attributes_for_create
      attributes.delete(primary_key) unless record.id?

      builder = Query::Builder.new(table_name, primary_key.to_s)
      adapter = Rome.adapter_class.new(builder)

      record.save_associations do
        adapter.insert(attributes) do |id|
          record.set_primary_key_after_create(id) unless record.id?
          record.new_record = false
        end
      end

      record.changes_applied
      record
    end

    # Updates one or many records identified by *id* in the database.
    #
    # ```
    # User.update(1, { name: julien })
    # User.update([1, 2, 3], { group_id: 2 })
    # ```
    def self.update(id, args) : Nil
      where({ primary_key => id }).update_all(args)
    end

    # :ditto:
    def self.update(id, **args) : Nil
      update(id, args)
    end

    # Deletes one or many records identified by *ids* from the database.
    #
    # ```
    # User.delete(1)
    # User.delete(1, 2, 3)
    # ```
    def self.delete(*ids) : Nil
      if ids.size == 1
        where({ primary_key => ids.first }).delete_all
      else
        where({ primary_key => ids.to_a }).delete_all
      end
    end
    # Persists the record into the database. Either creates a new row or
    # updates an existing row.
    # ```
    # user = User.new(name: "julien", group_id: 2)
    # user.save # => INSERT
    #
    # user.name = "alice"
    # user.save # => UPDATE
    # ```
    def save : Nil
      if persisted?
        update
      else
        self.class.create(self)
      end
    end

    # Updates a record into the database, optionally setting the specified
    # *attributes* if present.
    #
    # Automatically updates the `updated_at` column if it exists.
    #
    # Raises a `ReadOnlyRecord` exception if the record has been deleted.
    def update(**attributes) : self
      raise ReadOnlyRecord.new if deleted?

      unless attributes.empty?
        self.attributes = attributes
      end

      save_associations do
        if changed?
          if self.responds_to?(:updated_at=)
            self.updated_at = Time.utc
          end

          self.class.update(id, attributes_for_update.not_nil!)
        end
      end

      changes_applied
      self
    end

    # Deletes the record from the database. Marks the record as deleted.
    def delete : Nil
      self.class.delete(id)
      self.deleted = true
    end

    # Deletes the record and dependent associations from the database.
    # Marks the record as deleted.
    def destroy : Nil
      Rome.transaction do
        self.class.delete(id)
        self.deleted = true
        delete_associations
      end
    end

    # Reloads a record from the database. This will reset all changed attributes
    # and all change information.
    def reload : self
      builder = Query::Builder.new(self.class.table_name)
        .where!({ self.class.primary_key => id })
        .limit!(1)

      found = Rome.adapter_class.new(builder).select_one do |rs|
        self.attributes = rs
        true
      end
      raise RecordNotFound.new unless found

      clear_changes_information
      self
    end
  end
end
