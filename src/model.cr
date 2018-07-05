require "json"

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
      alias PrimaryKeyType = {{type}}

      @@primary_key = {{name.id.symbolize}}

      {% unless name.id.symbolize == :id %}
        def id : {{type}}
          {{name.id}}
        end

        def id? : {{type}}?
          {{name.id}}?
        end

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

    macro columns(**properties)
      @attributes = {} of String => ::Rome::Value

      {% for key, value in properties %}
        def {{key}}=(value : {{value[:type]}}{% if value[:nilable] %}?{% end %})
          @attributes[{{key.stringify}}] = value
        end

        def {{key}} : {{value[:type]}}{% if value[:nilable] %}?{% end %}
          {% if value[:nilable] %}
            @attributes[{{key.stringify}}]?.as({{value[:type]}}?)
          {% else %}
            @attributes
              .fetch({{key.stringify}}) { raise ::Rome::MissingAttribute.new("required attribute '{{key}}' is missing") }
              .as({{value[:type]}})
          {% end %}
        end

        def {{key}}? : {{value[:type]}}?
          @attributes[{{key.stringify}}]?.as({{value[:type]}}?)
        end

        {% if value[:primary] %}
          set_primary_key({{key}}, {{value[:type]}})
        {% end %}
      {% end %}

      def initialize(rs : DB::ResultSet)
        self.attributes = rs
      end

      def initialize(
        {% for key, value in properties %}
          {% if value[:default] %}
            {{key}} : {{value[:type]}}? = {{value[:default]}},
          {% else %}
            {{key}} : {{value[:type]}}? = nil,
          {% end %}
        {% end %}
      )
        {% for key, value in properties %}
          @attributes[{{key.stringify}}] = {{key}} unless {{key}}.nil?
        {% end %}
      end

      def attributes : NamedTuple
        {
          {% for key, value in properties %}
            {{key}}: self.{{key}},
          {% end %}
        }
      end

      def attributes=(args : NamedTuple) : Nil
        {% for key, value in properties %}
          if args.has_key?({{key.stringify}})
            {% if value[:nilable] %}
              @attributes[{{key.stringify}}] = args[{{key.stringify}}]?
            {% else %}
              @attributes[{{key.stringify}}] = args[{{key.stringify}}]?.not_nil!
            {% end %}
          end
        {% end %}
      end

      protected def attributes=(rs : DB::ResultSet) : Nil
        rs.each_column do |column_name|
          case column_name
            {% for key, value in properties %}
            when {{key.stringify}}
              @attributes[{{key.stringify}}] =
                {% if value[:converter] %}
                  {{value[:converter]}}.from_rs(rs)
                {% elsif value[:nilable] %}
                  rs.read({{value[:type]}}?)
                {% else %}
                  rs.read({{value[:type]}})
                {% end %}
            {% end %}
          else
            @attributes[column_name] = rs.read(::Rome::Value)
          end
        end
      end

      def to_h : Hash
        {
          {% for key, value in properties %}
            {{key.stringify}} => @attributes[{{key.stringify}}]?,
          {% end %}
        }
      end

      def self.new(%pull : JSON::PullParser) : self
        {% for key, value in properties %}
          {{key}} = nil
        {% end %}

        %location = %pull.location
        begin
          %pull.read_begin_object
        rescue %ex : ::JSON::ParseException
          raise ::JSON::MappingError.new(%ex.message, self.class.to_s, nil, *%location, %ex)
        end

        until %pull.kind == :end_object
          %location = %pull.location
          %name = %pull.read_object_key

          case %name
          {% for key, value in properties %}
          when {{key.stringify}}
            {{key}} = begin
              {% if value[:nilable] %} %pull.read_null_or do {% end %}

              {% if value[:converter] %}
                {{value[:converter]}}.from_json(%pull)
              {% else %}
                ::Union({{value[:type]}}).new(%pull)
              {% end %}

              {% if value[:nilable] %} end {% end %}
            rescue %ex : ::JSON::ParseException
              raise ::JSON::MappingError.new(%ex.message, self.class.to_s, %name, *%location, %ex)
            end
          {% end %}
          else
            self.on_unknown_json_attribute(%pull, %name, %location)
          end
        end

        new(
          {% for key, value in properties %}
            {{key}}: {{key}},
          {% end %}
        )
      end

      protected def self.on_unknown_json_attribute(pull, name, location)
        pull.skip
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
            json.field {{key.stringify}}, @attributes[{{key.stringify}}]?
          {% end %}
        end
      end
    end
  end
end
