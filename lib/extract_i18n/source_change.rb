# rubocop:disable Metrics/ParameterLists
require 'pastel'

module ExtractI18n
  class SourceChange
    # Data class for a proposed source change

    PASTEL = Pastel.new

    attr_reader :key, :i18n_string

    # i18n_key: "models.foo.bar.button_text"
    # interpolate_arguments: { "date" => "Date.new.to_s" }
    # source_line: original souce line to modify for viewing purposes
    # remove: what piece of source_line to replace
    def initialize(i18n_key:, i18n_string:, interpolate_arguments:, source_line:, remove:)
      @i18n_string = i18n_string
      @key = i18n_key
      @interpolate_arguments = interpolate_arguments
      @source_line = source_line
      @remove = remove
    end

    def format
      s = ""
      s += PASTEL.cyan("replace:  ") + PASTEL.blue(source_line).
        gsub(@remove, PASTEL.red(@remove))
      s += PASTEL.cyan("with:     ") + PASTEL.blue(source_line).
        gsub(@remove, PASTEL.green(i18n_t))
      s += PASTEL.cyan("add i18n: ") + PASTEL.blue("#{@key}: #{@i18n_string}")
      s
    end

    def i18n_t
      arguments = if @interpolate_arguments.keys.length > 0
                    ", " + @interpolate_arguments.map { |k, v| "#{k}: (#{v})" }.join(', ')
                  else
                    ""
                  end
      %{I18n.t("#{key}"#{arguments})}
    end
  end
end
