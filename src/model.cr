module Rome
  abstract class Model
    macro inherited
      class_property table_name : String = {{ @type.name.split("::").last.underscore + "s" }}
      class_getter primary_key : Symbol = :id
    end

    abstract def id
    abstract def id?
    abstract def attributes : NamedTuple
    abstract def attributes=(attrs : NamedTuple) : Nil
    abstract def to_h : Hash
    abstract def to_json : String
    abstract def to_json(io : IO) : Nil
    abstract def to_json(builder : JSON::Builder) : JSON::Builder

    @new_record = true
    protected def new_record=(@new_record); end
    protected def new_record?; @new_record; end

    @deleted = false
    protected def deleted=(@deleted); end
    protected def deleted?; @deleted; end

    def persisted?
      !(@new_record || @deleted)
    end

    private macro set_primary_key(name, type)
      @@primary_key = {{name.id.symbolize}}
      @{{name.id}} : {{type}} | Nil

      def id : {{type}}
        @{{name.id}}.not_nil!
      end

      def id? : {{type}}?
        @{{name.id}}
      end

      def id=(value : {{type}})
        @{{name.id}} = value
      end

      {% if %w(Int8 Int16 Int32 Int64).includes?(type.stringify) %}
        @[AlwaysInline]
        protected def set_primary_key_after_create(value : Int)
          @{{name.id}} = {{type}}.new(value)
        end
      {% else %}
        @[AlwaysInline]
        protected def set_primary_key_after_create(value : {{type}})
          @{{name.id}} = value
        end
      {% end %}

      @[AlwaysInline]
      protected def set_primary_key_after_create(value)
        raise "unreachable"
      end
    end

    macro columns(**properties)
      DB.mapping({{properties}}, strict: false)

      {% for key, value in properties %}
        {% if value[:primary] %}
          set_primary_key({{key}}, {{value[:type]}})
        {% end %}
      {% end %}

      def initialize(
        {% for key, value in properties %}
          {% unless value[:default] || value[:nilable] || value[:primary] %}
            @{{key}} : {{value[:type]}},
          {% end %}
        {% end %}

        {% for key, value in properties %}
          {% if value[:default] %}
            {% if value[:nilable] || value[:primary] %}
              @{{key}} : {{value[:type]}} | Nil = {{value[:default]}},
            {% else %}
              @{{key}} : {{value[:type]}} = {{value[:default]}},
            {% end %}
          {% elsif value[:nilable] || value[:primary] %}
            @{{key}} : {{value[:type]}} | Nil = nil,
          {% end %}
        {% end %}
      )
      end

      def attributes : NamedTuple
        {
          {% for key, value in properties %}
            {{key}}: @{{key}},
          {% end %}
        }
      end

      def attributes=(attrs : NamedTuple) : Nil
        {% for key, value in properties %}
          if attrs.has_key?({{key.symbolize}})
            {% if value[:nilable] || value[:primary_key] %}
              @{{key}} = attrs[{{key.symbolize}}]?
            {% else %}
              @{{key}} = attrs[{{key.symbolize}}]?.not_nil!
            {% end %}
          end
        {% end %}
      end

      def to_h : Hash
        {
          {% for key, value in properties %}
            {{key.stringify}} => @{{key}},
          {% end %}
        }
      end

      def to_json(indent = nil) : String
        String.build { |str| to_json(str, indent) }
      end

      def to_json(io : IO, indent = nil) : Nil
        JSON.build(io, indent) { |builder| to_json(builder) }
      end

      def to_json(json : JSON::Builder) : Nil
        json.object do
          {% for key, value in properties %}
            json.field {{key.stringify}}, @{{key.id}}
          {% end %}
        end
      end
    end
  end
end
