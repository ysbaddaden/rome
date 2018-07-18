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
        record.created_at ||= Time.now
      end
      if record.responds_to?(:updated_at=)
        record.updated_at ||= Time.now
      end

      attributes = record.attributes_for_create
      attributes.delete(primary_key) unless record.id?

      builder = Query::Builder.new(table_name, primary_key.to_s)
      adapter = Rome.adapter_class.new(builder)

      adapter.insert(attributes) do |id|
        record.set_primary_key_after_create(id) unless record.id?
        record.new_record = false
      end

      record.changes_applied
      record
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

      if changed?
        if self.responds_to?(:updated_at=)
          self.updated_at = Time.now
        end

        self.class
          .where({ self.class.primary_key => id })
          .update_all(attributes_for_update.not_nil!)

        changes_applied
      end

      self
    end

    # Deletes the record from the database. Marks the record as deleted.
    def delete : Nil
      self.class
        .where({ self.class.primary_key => id })
        .delete_all
      self.deleted = true
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
