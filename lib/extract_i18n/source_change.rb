# rubocop:disable Metrics/ParameterLists
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
    def initialize(i18n_key:, i18n_string:, interpolate_arguments:, source_line:, remove:, t_template: %{I18n.t("%s"%s)})
      @i18n_string = i18n_string
      @key = i18n_key
      @interpolate_arguments = interpolate_arguments
      @source_line = source_line
      @remove = remove
      @t_template = t_template
    end

    def format
      s = ""
      s += PASTEL.cyan("replace:  ") + PASTEL.blue(@source_line).
        gsub(@remove, PASTEL.red(@remove))
      unless @source_line.include?("\n")
        s += "\n"
      end
      s += PASTEL.cyan("with:     ") + PASTEL.blue(@source_line).
        gsub(@remove, PASTEL.green(i18n_t))
      unless @source_line.include?("\n")
        s += "\n"
      end
      s += PASTEL.cyan("add i18n: ") + PASTEL.blue("#{@key}: #{@i18n_string}")
      s
    end

    def i18n_t(relative: false)
      i18n_key = if relative
                   "." + key.split('.').last
                 else
                   key
                 end
      sprintf(@t_template, i18n_key, i18n_arguments_string)
    end

    def i18n_arguments_string
      if @interpolate_arguments.keys.length > 0
        ", " + @interpolate_arguments.map { |k, v| "#{k}: (#{v})" }.join(', ')
      else
        ""
      end
    end
  end
end
