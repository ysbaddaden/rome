module Rome
  abstract class Model
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

      builder = QueryBuilder.new(table_name, primary_key.to_s)
      adapter = Rome.adapter_class.new(builder)

      adapter.insert(attributes) do |id|
        record.set_primary_key_after_create(id) unless record.id?
        record.new_record = false
      end

      record.changes_applied
      record
    end

    def save : Nil
      if persisted?
        update
      else
        self.class.create(self)
      end
    end

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
          .update(attributes_for_update.not_nil!)

        changes_applied
      end

      self
    end

    def delete : Nil
      self.class
        .where({ self.class.primary_key => id })
        .delete
      self.deleted = true
    end

    def reload : self
      builder = QueryBuilder.new(self.class.table_name)
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
