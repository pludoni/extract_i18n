module ExtractI18n::Adapters
  class SlimAdapter < Adapter
    def run(original_content)
      @content = self.class.join_multiline(original_content.split("\n"))
      @content << "" # new line at the end
      @transformer = ExtractI18n::Slimkeyfy::SlimTransformer

      @new_content =
        @content.map do |old_line|
          process_line(old_line)
        end
      @new_content.join("\n")
    end

    def process_line(old_line)
      word = ExtractI18n::Slimkeyfy::Word.for('.slim').new(old_line)
      ExtractI18n::Slimkeyfy::SlimTransformer.new(word, @file_key).transform do |change|
        if change.nil? # nothing to do
          return old_line
        end

        if @on_ask.call(change)
          change.i18n_t
        else
          old_line
        end
      end
    end

    def self.join_multiline(strings_array)
      result = []
      joining_str = ''
      indent_length = 0
      long_str_start = /^[ ]+\| */
      long_str_indent = /^[ ]+/
      long_str_indent_with_vertical_bar = /^[ ]+\| */
      strings_array.each do |str|
        if joining_str.empty?
          if str[long_str_start]
            joining_str = str
            indent_length = str[long_str_start].length
          else
            result << str
          end
          # multiline string continues with spaces
        elsif str[long_str_indent] && str[long_str_indent].length.to_i >= indent_length
          joining_str << str.gsub(long_str_indent, ' ')
          # muliline string continues with spaces and vertical bar with same indentation
        elsif str[long_str_indent_with_vertical_bar] && str[long_str_indent_with_vertical_bar].length.to_i == indent_length
          joining_str << str.gsub(long_str_indent_with_vertical_bar, ' ')
          # multiline string ends
        else
          result << joining_str
          joining_str = ''
          indent_length = 0
          result << str
        end
      end
      result << joining_str unless joining_str.empty?

      result
    end
  end
end
