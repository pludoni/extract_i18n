# frozen_string_literal: true

require 'pastel'

module ExtractI18n
  class SourceChange
    # Data class for a proposed source change

    PASTEL = Pastel.new

    attr_reader :key, :i18n_string

    # @param i18n_key [String]
    #   "models.foo.bar.button_text"
    # @param interpolate_arguments [Hash]
    #   { "date" => "Date.new.to_s" }
    # @param source_line [String]
    #   original souce line to modify for viewing purposes
    # @param remove [String]
    #   what piece of source_line to replace
    # @param t_template [String]
    #   how to format the replacement translation, use 2 placeholder %s for the string and for the optional arguments
    # @param interpolation_type [Symbol]
    #   :ruby or :vue
    def initialize(
      i18n_key:,
      i18n_string:,
      interpolate_arguments:,
      source_line:,
      remove:,
      # we are using our own _t method by default
      t_template: %{_t("%s"%s)},
      interpolation_type: :ruby
    )
      @i18n_string = i18n_string
      @key = i18n_key
      @interpolate_arguments = interpolate_arguments
      @source_line = source_line
      @remove = remove
      @t_template = t_template
      @interpolation_type = interpolation_type
    end

    def format
      s = ""
      s += PASTEL.cyan("replace:  ") + PASTEL.blue(@source_line).
           gsub(@remove, PASTEL.red(@remove))
      unless @source_line.include?("\n")
        s += "\n"
      end
      if @source_line[@remove]
        s += PASTEL.cyan("with:     ") + PASTEL.blue(@source_line).
          gsub(@remove, PASTEL.green(i18n_t))
      else
        s += PASTEL.cyan("with:     ") + PASTEL.green(i18n_t)
      end
      unless @source_line.include?("\n")
        s += "\n"
      end
      # We are using a text extraction pipeline, so we don't need this line
      # s += PASTEL.cyan("add i18n: ") + PASTEL.yellow("#{@key}: #{@i18n_string}")
      s
    end

    def i18n_t(relative: false)
      i18n_key = if relative
                   "." + key.split('.').last
                 else
                   key
                 end
      # let's not have dangling commas for strings with no arguments
      @t_template = if i18n_arguments_string.length > 0
                      %{_t("%s"%s)}
                    else
                      %{_t("%s")}
                    end
      sprintf(@t_template, i18n_key, i18n_arguments_string)
    end

    def increment_key!
      if @key[/(.+)([0-9]+)$/]
        rest = $1
        number = $2.to_i
      else
        number = 1
        rest = @key
      end
      @key = "#{rest}#{number + 1}"
    end

    def i18n_arguments_string
      case @interpolation_type
      when :ruby
        if @interpolate_arguments.keys.length > 0
          ", " + @interpolate_arguments.map { |k, v| "#{k}: (#{v})" }.join(', ')
        else
          ""
        end
      when :vue
        if @interpolate_arguments.keys.length > 0
          ", { " + @interpolate_arguments.map { |k, v| "#{k}: (#{v.strip})" }.join(', ') + " }"
        else
          ""
        end
      else
        raise NotImplementedError, @interpolation_type
      end
    end
  end
end
