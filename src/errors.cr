module Rome
  class Error < Exception; end

  class RecordNotFound < Error; end

  class RecordNotSaved < Error; end

  class ReadOnlyRecord < Error; end

  class MissingAttribute < Error; end
end
