module ExtractI18n::Slimkeyfy
  class Word
    attr_reader :line, :tokens, :indentation

    def self.for(extension)
      if extension == 'vue'
        JsWord
      else
        Word
      end
    end

    def initialize(line)
      @line = line
      @indentation = " " * (@line.size - unindented_line.size)
    end

    def as_list
      # check for div.foo-bar(foo=bar)
      has_html_form = !!@line[/^ *[\.#]?[a-z\.#-]+\(/]
      delimiter_items =
        @line.
          sub(/^(\s*\|)(\w)/, "\\1 \\2"). # add a whitespace to support "|string"
          split(has_html_form ? /(?<=[\(])| +/ : ' '). # split by whitespace or ( but keep (
          drop_while { |i| i == "" } # .. but that leaves leading ""
      items = []
      # div: div
      delimiter_items.reverse_each do |item|
        if item[/^([a-z]|\.[a-z]|#[a-z]).*:/] and items.length > 0
          items[-1] = "#{item} #{items[-1]}"
        else
          items << item
        end
      end
      items.reverse
    end

    def unindented_line
      @line.sub(/^\s*/, "")
    end

    def head
      as_list.first
    end

    def tail
      as_list.drop(1)
    end

    def extract_arguments(translation)
      args = {}
      translation.scan(/\#{[^}]*}/).each_with_index do |arg, index|
        stripped_arg = arg[2..-2]
        key = arg[/\w+/]
        key += index.to_s if index > 0
        translation = translation.gsub(arg, "%{#{key}}")
        args[key] = stripped_arg
      end
      [args, translation]
    end

    def extract_updated_key(translation_key_with_base)
      return "" if translation_key_with_base.blank?
      translation_key_with_base.split(".").last
    end
  end

  class JsWord < Word
    def initialize(*args)
      super
      @use_absolute_key = true
    end

    def extract_arguments(translation)
      args = {}
      translation.scan(/\{\{([^}]*)\}\}/).each_with_index do |stripped_arg, index|
        arg = Regexp.last_match[0]
        key = arg[/\w+/]
        key += index.to_s if index > 0
        translation = translation.gsub(arg, "{#{key}}")
        args[key] = stripped_arg[0]
      end
      [args, translation]
    end
  end
end
