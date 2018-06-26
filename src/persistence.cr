module Rome
  abstract class Model
    def self.create(**args) : self?
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

      attrs = record.to_h
      attrs.delete(primary_key.to_s) unless record.id?

      builder = QueryBuilder.new(table_name, primary_key.to_s)
      adapter = Rome.adapter_class.new(builder)

      adapter.insert(attrs) do |id|
        record.set_primary_key_after_create(id) unless record.id?
        record.new_record = false
      end

      record
    end

    def save : Nil
      if persisted?
        update(**attributes)
      else
        self.class.create(self)
      end
    end

    def update(**attrs) : Nil
      raise ReadOnlyRecord.new if deleted?

      self.attributes = attrs

      if self.responds_to?(:updated_at=)
        self.updated_at = Time.now
      end

      self.class
        .where({ self.class.primary_key => id })
        .update(**attributes)
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

      self
    end
  end
end
