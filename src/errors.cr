module Rome
  class Error < Exception; end

  class RecordNotFound < Error; end

  class ReadOnlyRecord < Error; end
end
