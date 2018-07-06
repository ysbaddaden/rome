require "json"

module Rome
  abstract class Model
    macro inherited
      class_property table_name : String = {{ @type.name.split("::").last.underscore + "s" }}
      class_getter primary_key : Symbol = :id
    end

    abstract def id
    abstract def id?
    abstract def attributes=(attrs : NamedTuple) : Nil
    abstract def to_h : Hash
    abstract def to_json : String
    abstract def to_json(io : IO) : Nil
    abstract def to_json(builder : JSON::Builder) : JSON::Builder

    @changed_attributes : Hash(Symbol, ::Rome::Value)?
    @extra_attributes : Hash(String, ::Rome::Value)?
    @new_record = true
    @deleted = false

    protected def changed_attributes : Hash(Symbol, ::Rome::Value)
      @changed_attributes ||= {} of Symbol => ::Rome::Value
    end

    protected def extra_attributes=(@extra_attributes : Hash(String, ::Rome::Value))
    end

    protected def extra_attributes : Hash(String, ::Rome::Value)
      @extra_attributes ||= {} of String => ::Rome::Value
    end

    def changed? : Bool
      if changed = @changed_attributes
        !changed.empty?
      else
        false
      end
    end

    def changes_applied
      @changed_attributes.try(&.clear)
    end

    def clear_changes_information
      @changed_attributes.try(&.clear)
    end

    protected def new_record=(@new_record); end
    protected def new_record?; @new_record; end

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
      {% for key, opts in properties %}
        {% opts[:nilable_type] = "::Union(#{opts[:type]}, Nil)".id %}
        {% opts[:type] = opts[:nilable_type] if opts[:nilable] %}
      {% end %}

      def self.new(%rs : ::DB::ResultSet)
        %extra_attributes = nil

        {% for key, opts in properties %}
          {{key}} = nil
        {% end %}

        %rs.each_column do |%column_name|
          case %column_name
            {% for key, opts in properties %}
            when {{key.stringify}}
              {{key}} =
                {% if opts[:converter] %}
                  {{opts[:converter]}}.from_rs(%rs)
                {% elsif opts[:nilable] %}
                  %rs.read({{opts[:nilable_type]}})
                {% else %}
                  %rs.read({{opts[:type]}})
                {% end %}
            {% end %}
          else
            %extra_attributes ||= {} of String => ::Rome::Value
            %extra_attributes[%column_name] = %rs.read(::Rome::Value)
          end
        end

        %record = new(
          {% for key, opts in properties %}
            {{key}}: {{key}},
          {% end %}
        )
        %record.extra_attributes = %extra_attributes if %extra_attributes
        %record.new_record = false
        %record
      end

      def initialize(
        {% for key, opts in properties %}
          @{{key}} : {{opts[:nilable_type]}} = {{opts[:default] || "nil".id }},
        {% end %}
      )
      end

      {% for key, opts in properties %}
        @{{key}} : {{opts[:nilable_type]}}

        def {{key}}=(value : {{opts[:nilable_type]}})
          {{key}}_will_change! unless value == @{{key}}
          @{{key}} = value
        end

        def {{key}} : {{opts[:nilable_type]}}
          @{{key}} {% unless opts[:nilable] %}||
            raise ::Rome::MissingAttribute.new("required attribute #{self.class.name}\#{{key}} is missing")
          {% end %}
        end

        def {{key}}? : {{opts[:nilable_type]}}
          @{{key}}
        end

        def {{key}}_will_change! : Nil
          unless changed_attributes.has_key?({{key.symbolize}})
            changed_attributes[{{key.symbolize}}] = @{{key}}
          end
        end

        def {{key}}_changed? : Bool
          !!@changed_attributes.try(&.has_key?({{key.symbolize}}))
        end

        def {{key}}_was : {{opts[:nilable_type]}}
          @changed_attributes
            .try(&.fetch({{key.symbolize}}) { nil })
            .as({{opts[:nilable_type]}})
        end

        def {{key}}_change : Tuple({{opts[:nilable_type]}}, {{opts[:nilable_type]}})
          {
            {{key}}_was,
            {{key}}?,
          }
        end

        {% if opts[:primary] %}
          set_primary_key({{key}}, {{opts[:type]}})
        {% end %}
      {% end %}

      def [](attr_name : Symbol) : ::Rome::Value
         case attr_name
         {% for key, opts in properties %}
         when {{key.symbolize}}
           @{{key}} {% unless opts[:nilable] %}||
             raise ::Rome::MissingAttribute.new("required attribute #{self.class.name}[:{{key}}] is missing")
           {% end %}
         {% end %}
         else
           raise ::Rome::MissingAttribute.new("no such attribute: #{self.class.name}[:#{attr_name}]")
         end
      end

      def []?(attr_name : Symbol) : ::Rome::Value
         case attr_name
         {% for key, opts in properties %}
         when {{key.symbolize}}
           @{{key}}
         {% end %}
         end
      end

      def [](attr_name : String) : ::Rome::Value
         case attr_name
         {% for key, opts in properties %}
         when {{key.stringify}}
           @{{key}} {% unless opts[:nilable] %} ||
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

      protected def attributes_for_create
        {
          {% for key, opts in properties %}
            {% if opts[:nilable] || opts[:primary] %}
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

      def attributes=(args : NamedTuple) : Nil
        {% for key, opts in properties %}
          if args.has_key?({{key.symbolize}})
            {% if opts[:nilable] %}
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
                {% elsif opts[:nilable] %}
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

      def to_h : Hash
        hsh = @extra_attributes.dup || {} of String => ::Rome::Value
        {% for key, opts in properties %}
          hsh[{{key.stringify}}] = {{key}}?
        {% end %}
        hsh
      end

      def self.new(%pull : JSON::PullParser) : self
        {% for key, opts in properties %}
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
          {% for key, opts in properties %}
          when {{key.stringify}}
            {{key}} = begin
              {% if opts[:nilable] %} %pull.read_null_or do {% end %}

              {% if opts[:converter] %}
                {{opts[:converter]}}.from_json(%pull)
              {% else %}
                {{opts[:nilable_type]}}.new(%pull)
              {% end %}

              {% if opts[:nilable] %} end {% end %}
            rescue %ex : ::JSON::ParseException
              raise ::JSON::MappingError.new(%ex.message, self.class.to_s, %name, *%location, %ex)
            end
          {% end %}
          else
            %pull.skip
          end
        end

        new(
          {% for key, opts in properties %}
            {{key}}: {{key}},
          {% end %}
        )
      end

      def to_json(indent = nil) : String
        String.build { |str| to_json(str, indent) }
      end

      def to_json(io : IO, indent = nil) : Nil
        JSON.build(io, indent) { |builder| to_json(builder) }
      end

      def to_json(json : JSON::Builder) : Nil
        json.object do
          {% for key, opts in properties %}
            json.field({{key.stringify}}, @{{key}})
          {% end %}

          if extra_attributes = @extra_attributes
            extra_attributes.each do |key, opts|
              json.field(key, opts)
            end
          end
        end
      end
    end
  end
end
