require "json"

module Rome
  module Serialization
    # Exports the record as JSON, including all attributes and the extra
    # attributes loaded from the database.
    def to_json(indent = nil) : String
      String.build { |str| to_json(str, indent) }
    end

    # :ditto:
    def to_json(io : IO, indent = nil) : Nil
      JSON.build(io, indent) { |builder| to_json(builder) }
    end

    # :ditto:
    def to_json(builder : JSON::Builder) : JSON::Builder
      {% raise "unreachable" %}
    end

    # Initializes a record from a JSON parser. This considers the record to be
    # a new record and not persisted. See `#attributes=(JSON::PullParser)` to
    # update a persisted record.
    #
    # ```
    # user = User.new(JSON::PullParser(string_or_io))
    # ```
    def self.new(pull : JSON::PullParser) : self
      raise "not implemented"
    end

    # Sets many attributes at once from a JSON parser. For example:
    #
    # ```
    # user = User.find(1)
    # user.attributes = JSON::PullParser.new(string_or_io)
    # ```
    def attributes=(pull : JSON::PullParser) : Nil
      {% raise "unreachable" %}
    end

    # :nodoc:
    macro set_json_methods(properties, strict)
      # :nodoc:
      def self.new(pull : JSON::PullParser) : self
        {% for key, opts in properties %}
          var_{{key}} = nil
        {% end %}

        %location = pull.location
        begin
          pull.read_begin_object
        rescue %ex : ::JSON::ParseException
          raise ::JSON::MappingError.new(%ex.message, self.class.to_s, nil, *%location, %ex)
        end

        until pull.kind == :end_object
          %location = pull.location
          %name = pull.read_object_key

          case %name
          {% for key, opts in properties %}
          when {{key.stringify}}
            var_{{key}} = begin
              {% if opts[:null] %} pull.read_null_or do {% end %}

              {% if opts[:converter] %}
                {{opts[:converter]}}.from_json(pull)
              {% else %}
                {{opts[:nilable_type]}}.new(pull)
              {% end %}

              {% if opts[:null] %} end {% end %}
            rescue %ex : ::JSON::ParseException
              raise ::JSON::MappingError.new(%ex.message, self.class.to_s, %name, *%location, %ex)
            end
          {% end %}
          else
            pull.skip
          end
        end

        new(
          {% for key, opts in properties %}
            {{key}}: var_{{key}},
          {% end %}
        )
      end

      # :nodoc:
      def attributes=(pull : JSON::PullParser) : Nil
        location = pull.location
        begin
          pull.read_begin_object
        rescue ex : ::JSON::ParseException
          raise ::JSON::MappingError.new(ex.message, self.class.to_s, nil, *location, ex)
        end

        until pull.kind == :end_object
          location = pull.location
          name = pull.read_object_key

          case name
          {% for key, opts in properties %}
          when {{key.stringify}}
            @{{key}} = begin
              {% if opts[:null] %} pull.read_null_or do {% end %}

              {% if opts[:converter] %}
                {{opts[:converter]}}.from_json(pull)
              {% else %}
                {{opts[:nilable_type]}}.new(pull)
              {% end %}

              {% if opts[:null] %} end {% end %}
            rescue ex : ::JSON::ParseException
              raise ::JSON::MappingError.new(ex.message, self.class.to_s, name, *location, ex)
            end
          {% end %}
          else
            pull.skip
          end
        end
      end

      # :nodoc:
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
