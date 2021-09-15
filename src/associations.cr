require "./relation"

module Rome
  module Associations
    annotation BelongsTo; end
    annotation HasOne; end
    annotation HasMany; end

    # Declares a belongs to relationship.
    #
    # This will add the following methods:
    # - `association` returns the associated object (or nil).
    # - `association=` assigns the associated object, assigning the foreign key;
    # - `reload_association` to reload the associated object.
    #
    # For example a Book class declares `belongs_to :author` which will add:
    #
    # - `Book#author` (similar to `Author.find(author_id)`)
    # - `Book#author=(author)` (similar to `book.author_id = author.id`)
    # - `Book#reload_author`
    macro belongs_to(name, class_name = nil, foreign_key = nil, autosave = nil, dependent = nil)
      {% unless class_name
           class_name = name.id.stringify.camelcase.id
         end %}
      {% unless foreign_key
           foreign_key = (name.id.stringify + "_id").id
         end %}

      @[::Rome::Associations::BelongsTo(class_name: {{class_name}}, foreign_key: {{foreign_key}}, autosave: {{autosave}}, dependent: {{dependent}})]
      @{{name.id}} : {{class_name}}?

      def {{name.id}} : {{class_name}}
        @{{name.id}} || reload_{{name.id}}
      end

      def {{name.id}}=(record : {{class_name}}) : {{class_name}}
        self.{{foreign_key.id}} = record.id unless record.new_record?
        @{{name.id}} = record
      end

      def build_{{name.id}}(**attributes) : {{class_name}}
        self.{{name.id}} = {{class_name}}.new(**attributes)
      end

      def create_{{name.id}}(**attributes) : {{class_name}}
        self.{{name.id}} = {{class_name}}.create(**attributes)
      end

      def create_{{name.id}}!(**attributes) : {{class_name}}
        self.{{name.id}} = {{class_name}}.create!(**attributes)
      end

      def reload_{{name.id}} : {{class_name}}
        @{{name.id}} = {{class_name}}.find({{foreign_key}})
      end
    end

    # Declares a has one relationship.
    #
    # This will add the following methods:
    # - `association` returns the associated object (or nil).
    # - `association=` assigns the associated object, assigning the
    #   association's foreign key, then saving the association; permanently
    #   deletes the previously associated object;
    # - `reload_association` to reload the associated object.
    #
    # For example an Account class declares `has_one :supplier` which will add:
    #
    # - `Account#supplier` (similar to `Supplier.find_by(account_id: account.id)`)
    # - `Account#supplier=(supplier)` (similar to `supplier.account_id = account.id`)
    # - `Account#reload_supplier`
    macro has_one(name, class_name = nil, foreign_key = nil, autosave = nil, dependent = nil)
      {% unless class_name
           class_name = name.id.stringify.camelcase.id
         end %}
      {% unless foreign_key
           foreign_key = (@type.id.stringify.split("::").last + "_id").underscore.id
         end %}

      @[::Rome::Associations::HasOne(class_name: {{class_name}}, foreign_key: {{foreign_key}}, autosave: {{autosave}}, dependent: {{dependent}})]
      @{{name.id}} : {{class_name}}?

      def {{name.id}} : {{class_name}}
        @{{name.id}} || reload_{{name.id}}
      end

      def {{name.id}}=(record : {{class_name}}) : {{class_name}}
        unless new_record?
          if previous_id = record.{{foreign_key.id}}
            %query = {{class_name}}.where({{foreign_key.id}}: previous_id)
            case {{dependent}}
            when :delete
              %query.delete_all
            else # :nullify
              %query.update_all({{foreign_key.id}}: nil)
            end
          end
          record.{{foreign_key.id}} = id
          record.save
        end
        @{{name.id}} = record
      end

      def build_{{name.id}}(**attributes) : {{class_name}}
        record = {{class_name}}.new(**attributes)
        record.{{foreign_key.id}} = id unless new_record?
        @{{name.id}} = record
      end

      def create_{{name.id}}(**attributes) : {{class_name}}
        raise RecordNotSaved.new("can't initialize {{class_name}} for #{self.class.name} doesn't have an id.") unless id?
        build(**attributes).tap(&.save)
      end

      def create_{{name.id}}!(**attributes) : {{class_name}}
        raise RecordNotSaved.new("can't initialize {{class_name}} for #{self.class.name} doesn't have an id.") unless id?
        build(**attributes).tap(&.save!)
      end

      def reload_{{name.id}} : {{class_name}}
        @{{name.id}} = {{class_name}}.find_by({{foreign_key}}: id)
      end
    end

    # Declares a has many relationship.
    macro has_many(name, class_name = nil, foreign_key = nil, autosave = nil, dependent = nil)
      {% unless class_name
           class_name = name.id.stringify.gsub(/s$/, "").camelcase.id
         end %}
      {% unless foreign_key
           foreign_key = (@type.id.stringify.split("::").last.gsub(/s$/, "") + "_id").underscore.id
         end %}

      @[::Rome::Associations::HasMany(class_name: {{class_name}}, foreign_key: {{foreign_key}}, autosave: {{autosave}}, dependent: {{dependent}})]
      @{{name.id}} : ::Rome::Relation({{class_name}})?

      def {{name.id}} : ::Rome::Relation({{class_name}})
        @{{name.id}} ||= ::Rome::Relation({{class_name}}).new(self, {{foreign_key.id.symbolize}})
      end
    end

    protected def save_associations
      {% for ivar in @type.instance_vars %}
        {% if ann = ivar.annotation(::Rome::Associations::BelongsTo) %}
          {% unless ann[:autosave] == false %}
            if (%record = @{{ivar.id}}) {% if ann[:autosave] == nil %} && %record.new_record? {% end %}
              %record.save
              self.{{ann[:foreign_key].id}} = %record.id
            end
          {% end %}
        {% end %}
      {% end %}

      yield

      {% for ivar in @type.instance_vars %}
        {% if ann = ivar.annotation(::Rome::Associations::HasOne) %}
          {% unless ann[:autosave] == false %}
            if (%record = @{{ivar.id}}) {% if ann[:autosave] == nil %} && %record.new_record? {% end %}
              %record.{{ann[:foreign_key].id}} = id
              %record.save
            end
          {% end %}
        {% elsif ann = ivar.annotation(::Rome::Associations::HasMany) %}
          {% unless ann[:autosave] == false %}
            if %records = @{{ivar.id}}
              if %records.cached?
                %records.each do |%record|
                  {% if ann[:autosave] == nil %} next unless %record.new_record? {% end %}
                  %record.{{ann[:foreign_key].id}} = id
                  %record.save
                end
              end
            end
          {% end %}
        {% end %}
      {% end %}
    end

    protected def delete_associations
      {% for ivar in @type.instance_vars %}
        {% if ann = ivar.annotation(::Rome::Associations::BelongsTo) %}
          {% if ann[:dependent] %}}
            if {{foreign_key.id}}?
              {% if ann[:dependent] == :destroy %}
                self.{{ivar.id}}.try(&.destroy)
              {% elsif ann[:dependent] == :delete %}
                {{ann[:class_name]}}
                  .where({ {{ann[:class_name]}}.primary_key => {{foreign_key.id}} })
                  .delete_all
              {% elsif ann[:dependent] == :nullify %}
                {{ann[:class_name]}}
                  .where({ {{ann[:class_name]}}.primary_key => {{foreign_key.id}} })
                  .update_all({{ann[:foreign_key]}}: id)
              {% end %}
            end
          {% end %}

        {% elsif ann = ivar.annotation(::Rome::Associations::HasOne) %}
          {% if ann[:dependent] == :destroy %}
            self.{{ivar.id}}.try(&.destroy)
          {% elsif ann[:dependent] == :delete %}
            {{ann[:class_name]}}
              .where({{ann[:foreign_key]}}: id)
              .delete_all
          {% elsif ann[:dependent] == :nullify %}
            {{ann[:class_name]}}
              .where({{ann[:foreign_key]}}: id)
              .update_all({{ann[:foreign_key]}}: id)
          {% end %}

        {% elsif ann = ivar.annotation(::Rome::Associations::HasMany) %}
          {% if ann[:dependent] == :destroy %}
            self.{{ivar.id}}.try(&.each(&.destroy))
          {% elsif ann[:dependent] == :delete_all %}
            {{ann[:class_name]}}
              .where({{ann[:foreign_key]}}: id)
              .delete_all
          {% elsif ann[:dependent] == :nullify %}
            {{ann[:class_name]}}
              .where({{ann[:foreign_key]}}: id)
              .update_all({{ann[:foreign_key]}}: id)
          {% end %}
        {% end %}
      {% end %}
    end
  end
end
