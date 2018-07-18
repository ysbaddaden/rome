require "./query"
require "./serialization"

module Rome
  abstract class Model
    extend Query
    include Serialization

    macro inherited
      class_property table_name : String = {{ @type.name.split("::").last.underscore + "s" }}
      class_getter primary_key : Symbol = :id
    end

    # Always returns this record's primary key value, even when the primary key
    # isn't named `id`.
    abstract def id

    # Same as `id` but may return `nil` when the record hasn't been saved
    # instead of raising.
    abstract def id?

    @extra_attributes : Hash(String, ::Rome::Value)?
    @changed_attributes : Hash(Symbol, ::Rome::Value)?

    protected def extra_attributes=(@extra_attributes : Hash(String, Value))
    end

    protected def changed_attributes : Hash(Symbol, ::Rome::Value)
      @changed_attributes ||= {} of Symbol => ::Rome::Value
    end

    protected def extra_attributes : Hash(String, Value)
      @extra_attributes ||= {} of String => Value
    end

    # Returns true if the record hasn't been saved to the database, yet.
    getter? new_record : Bool = true
    protected setter new_record : Bool

    # Returns true if the record has been deleted from the database.
    getter? deleted : Bool = false
    protected setter deleted : Bool

    # Returns true is the record is known to exist in the database (has either
    # been loaded or saved and not deleted).
    def persisted? : Bool
      !(@new_record || @deleted)
    end

    # Generic accessor for an attribute. Only valid for known columns. Raises a
    # `Rome::MissingAttribute` exception when the attribute is undefined (e.g.
    # not loaded from the database).
    abstract def [](attr_name : Symbol) : Value

    # Generic accessor for an attribute. Returns `nil` when the attribute is
    # undefined (e.g. not loaded from the database).
    abstract def []?(attr_name : Symbol) : Value?

    # Generic accessor for an attribute or extraneous attribute. Raises a
    # `Rome::MissingAttribute` exception when the attribute is undefined (e.g.
    # not loaded from the database).
    abstract def [](attr_name : String) : Value

    # Generic accessor for an attribute or extraneous attribute. Returns `nil`
    # when the attribute is undefined (e.g. not loaded from the database).
    abstract def []?(attr_name : String) : Value?

    # Sets many attributes at once. For example:
    #
    # ```
    # user = User.find(1)
    # user.attributes = {
    #   group_id: 2,
    #   name: "julien",
    # }
    #
    # user.group_id  # => 2
    # user.name      # => "julien"
    # ```
    abstract def attributes=(attrs : NamedTuple) : Nil

    # Exports this record as a Hash.
    abstract def to_h : Hash

    # Returns true if any attribute has changed since this model was initialized
    # or last saved.
    def changed? : Bool
      if changed = @changed_attributes
        !changed.empty?
      else
        false
      end
    end

    # Returns the list of changed attributes.
    def changes : Hash(Symbol, ::Tuple(::Rome::Value, ::Rome::Value))
      changes = {} of Symbol => {::Rome::Value, ::Rome::Value}
      @changed_attributes.try(&.each { |k, v| changes[k] = {v, self[k]?} })
      changes
    end

    # Tell that all changes have been applied to the database, thus clearing all
    # change information.
    def changes_applied : Nil
      @changed_attributes.try(&.clear)
    end

    # Clears all dirty attribute information.
    def clear_changes_information : Nil
      @changed_attributes.try(&.clear)
    end

    # Restores all dirty attributes to their pristine value. Eventually clears
    # change information.
    abstract def restore_attributes : Nil

    # Sets the primary key for this model.
    private macro set_primary_key(name, type)
      # :nodoc:
      alias PrimaryKeyType = {{type}}

      @@primary_key = {{name.id.symbolize}}

      {% unless name.id.symbolize == :id %}
        # Generic accessor for `#{{name.id}}`
        def id : {{type}}
          {{name.id}}
        end

        # Generic accessor for `#{{name.id}}?`
        def id? : {{type}}?
          {{name.id}}?
        end

        # Generic accessor for `#{{name.id}}=`
        def id=(value : {{type}})
          self.{{name.id}} = value
        end
      {% end %}

      {% if %w(Int8 Int16 Int32 Int64).includes?(type.stringify) %}
        @[AlwaysInline]
        protected def set_primary_key_after_create(value : Int)
          self.{{name.id}} = {{type}}.new(value)
        end
      {% else %}
        @[AlwaysInline]
        protected def set_primary_key_after_create(value : {{type}})
          self.{{name.id}} = value
        end
      {% end %}

      @[AlwaysInline]
      protected def set_primary_key_after_create(value)
        raise "unreachable"
      end
    end

    # Declares the model schema. For example:
    # ```
    # class User < Rome::Model
    #   columns(
    #     id:       {type: Int32, primary_key: true},
    #     group_id: {type: UUID, null: true},
    #     name:     {type: String},
    #   )
    # end
    # ```
    #
    # Available options:
    #
    # - `type` —the column type (required);
    # - `primary_key` —whether the column is the table primary key (default: false);
    # - `null` —whether the column accepts NULL values (default: false).
    # - `converter` —specify a converter type that must implement
    # `.from_rs(DB::ResultSet)` and should implement
    # `.from_json(JSON::PullParser)`.
    #
    macro columns(properties, strict = false)
      {% for key, opts in properties %}
        {% if strict %}
          {% opts[:null] = true if opts[:primary_key] %}
        {% end %}
        {% opts[:nilable_type] = "#{opts[:type]}?".id %}
        {% opts[:type] = opts[:nilable_type] if opts[:null] %}
        {% opts[:ivar_type] = strict ? opts[:type] : opts[:nilable_type] %}
      {% end %}

      #::Rome::Query.set_methods({{properties}}, strict)
      ::Rome::Serialization.set_json_methods({{properties}}, strict)

      # :nodoc:
      def self.new(rs : ::DB::ResultSet)
        %extra_attributes = nil

        {% for key, opts in properties %}
          var_{{key}} = nil
        {% end %}

        rs.each_column do |%column_name|
          case %column_name
            {% for key, opts in properties %}
            when {{key.stringify}}
              var_{{key}} =
                {% if opts[:converter] %}
                  {{opts[:converter]}}.from_rs(rs)
                {% elsif opts[:null] %}
                  rs.read({{opts[:nilable_type]}})
                {% else %}
                  rs.read({{opts[:type]}})
                {% end %}
            {% end %}
          else
            %extra_attributes ||= {} of String => ::Rome::Value
            %extra_attributes[%column_name] = rs.read(::Rome::Value)
          end
        end

        %record = new(
          {% for key, opts in properties %}
            {{key}}: var_{{key}},
          {% end %}
        )
        %record.extra_attributes = %extra_attributes if %extra_attributes
        %record.new_record = false
        %record
      end

      def initialize(
        {% if strict %}
          {% for key, opts in properties %}
            {% unless opts[:null] || opts[:default] %}
              @{{key}} : {{opts[:ivar_type]}},
            {% end %}
          {% end %}
        {% end %}
        {% for key, opts in properties %}
          {% if !strict || opts[:null] || opts[:default] %}
            @{{key}} : {{opts[:ivar_type]}} = {{opts[:default] || "nil".id }},
          {% end %}
        {% end %}
      )
      end

      {% for key, opts in properties %}
        @{{key}} : {{opts[:ivar_type]}}

        # Set {{key}} attribute.
        def {{key}}=(value : {{opts[:type]}}) : {{opts[:type]}}
          {{key}}_will_change! unless value == @{{key}}
          @{{key}} = value
        end

        # Returns {{key}} attribute. {% unless opts[:null] %}Raises a
        # `Rome::MissingAttribute` exception when undefined.{% end %}
        def {{key}} : {{opts[:type]}}
          @{{key}} {% unless opts[:null] %}||
            raise ::Rome::MissingAttribute.new("required attribute #{self.class.name}\#{{key}} is missing")
          {% end %}
        end

        # Returns {{key}} attribute. Returns `nil` when undefined.
        def {{key}}? : {{opts[:nilable_type]}}
          @{{key}}
        end

        # Call before changing or mutating {{key}}. Only required to be called
        # when `#{{key}}=` can't detect a mutation.
        def {{key}}_will_change! : Nil
          unless changed_attributes.has_key?({{key.symbolize}})
            changed_attributes[{{key.symbolize}}] = @{{key}}
          end
        end

        # Returns true if {{key}} has changed.
        def {{key}}_changed? : Bool
          !!@changed_attributes.try(&.has_key?({{key.symbolize}}))
        end

        # Returns the previous value of {{key}} if it has changed. Returns
        # `nil` otherwise.
        def {{key}}_was : {{opts[:nilable_type]}}
          @changed_attributes
            .try(&.fetch({{key.symbolize}}) { nil })
            .as({{opts[:nilable_type]}})
        end

        # Returns the previous and actual values of {{key}}. If {{key}} didn't
        # change the previous value is `nil`.
        def {{key}}_change : ::Tuple({{opts[:nilable_type]}}, {{opts[:nilable_type]}})
          {
            {{key}}_was,
            {{key}}?,
          }
        end

        {% if opts[:primary_key] %}
          set_primary_key({{key}}, {{opts[:type]}})
        {% end %}
      {% end %}

      # :nodoc:
      def [](attr_name : Symbol) : ::Rome::Value
         case attr_name
         {% for key, opts in properties %}
         when {{key.symbolize}}
           @{{key}} {% unless opts[:null] %}||
             raise ::Rome::MissingAttribute.new("required attribute #{self.class.name}[:{{key}}] is missing")
           {% end %}
         {% end %}
         else
           raise ::Rome::MissingAttribute.new("no such attribute: #{self.class.name}[:#{attr_name}]")
         end
      end

      # :nodoc:
      def []?(attr_name : Symbol) : ::Rome::Value
         case attr_name
         {% for key, opts in properties %}
         when {{key.symbolize}}
           @{{key}}
         {% end %}
         end
      end

      # :nodoc:
      def [](attr_name : String) : ::Rome::Value
         case attr_name
         {% for key, opts in properties %}
         when {{key.stringify}}
           @{{key}} {% unless opts[:null] %} ||
             raise ::Rome::MissingAttribute.new(%(required attribute #{self.class.name}[{{key.stringify}}] is missing))
           {% end %}
         {% end %}
         else
           if (extra = @extra_attributes) && extra.has_key?(attr_name)
             extra[attr_name]
           else
             raise ::Rome::MissingAttribute.new(%(no such attribute: #{self.class.name}["#{attr_name}"]))
           end
         end
      end

      # :nodoc:
      def []?(attr_name : String) : ::Rome::Value
         case attr_name
         {% for key, opts in properties %}
         when {{key.stringify}}
           @{{key}}
         {% end %}
         else
           if (extra = @extra_attributes) && extra.has_key?(attr_name)
             extra[attr_name]
           end
         end
      end

      # :nodoc:
      def attributes=(args : NamedTuple) : Nil
        {% for key, opts in properties %}
          if args.has_key?({{key.symbolize}})
            {% if opts[:null] %}
              self.{{key}} = args[{{key.symbolize}}]?
            {% else %}
              self.{{key}} = args[{{key.symbolize}}]?.not_nil!
            {% end %}
          end
        {% end %}
      end

      protected def attributes=(rs : ::DB::ResultSet) : Nil
        rs.each_column do |column_name|
          case column_name
            {% for key, opts in properties %}
            when {{key.stringify}}
              @{{key}} =
                {% if opts[:converter] %}
                  {{opts[:converter]}}.from_rs(rs)
                {% elsif opts[:null] %}
                  rs.read({{opts[:nilable_type]}})
                {% else %}
                  rs.read({{opts[:type]}})
                {% end %}
            {% end %}
          else
            extra_attributes[column_name] = rs.read(::Rome::Value)
          end
        end
      end

      protected def attributes_for_create
        {
          {% for key, opts in properties %}
            {% if opts[:null] || opts[:primary_key] %}
              {{key.symbolize}} => {{key}}?,
            {% else %}
              {{key.symbolize}} => {{key}},
            {% end %}
          {% end %}
        }
      end

      protected def attributes_for_update
        if changed = @changed_attributes
          hsh = {} of Symbol => ::Rome::Value
          changed.each_key { |key| hsh[key] = self[key] }
          hsh
        end
      end

      # :nodoc:
      def restore_attributes : Nil
        return unless changed_attributes = @changed_attributes

        changed_attributes.each do |attr_name, value|
          case attr_name
          {% for key, opts in properties %}
          when {{key.symbolize}}
            @{{key}} = value.as({{opts[:nilable_type]}})
          {% end %}
          else
            raise "unreachable"
          end
        end

        clear_changes_information
      end

      # :nodoc:
      def to_h : Hash
        hsh = @extra_attributes.dup || {} of String => ::Rome::Value
        {% for key, opts in properties %}
          hsh[{{key.stringify}}] = {{key}}?
        {% end %}
        hsh
      end
    end

    # See `#columns(properties, strict)`.
    macro columns(**properties)
      ::Rome::Model.columns({{properties}}, strict: false)
    end
  end
end
