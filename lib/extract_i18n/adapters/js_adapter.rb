require 'open3'
require 'json'

module ExtractI18n::Adapters
  class JsAdapter < Adapter
    IGNORE_AFTER = /(key: *|import .*|require\(.*)/

    def run(original_context)
      path = '../../../js/find_string_tokens.js'
      abs_path = File.expand_path(path, __dir__)
      stdout, stderr, status = Open3.capture3('node', abs_path, stdin_data: original_context)
      unless status.success?
        warn stderr
        warn "Failed to run js/find_string_tokens.js: #{status}"
        return original_context
      end
      @current_buffer = original_context.dup
      @original_context = original_context.dup.freeze

      @t_template = %[t('%s'%s)]
      if vue2?(original_context)
        @t_template = %[this.$t('%s'%s)]
      end

      @byte_offset = 0

      results = ::JSON.parse(stdout, symbolize_names: true)
      results.each do |item|
        if item[:type] == 'literal'
          replace_string(item)
        else
          warn "Template String literals not implemented yet: #{JSON.pretty_generate(item)}"
        end
      end
      @current_buffer
    end

    def replace_string(item)
      content = item[:value]
      start = [item.dig(:loc, :start, :line) - 1, item.dig(:loc, :start, :column)]
      finish = [item.dig(:loc, :end, :line) - 1, item.dig(:loc, :end, :column)]

      source_line = @original_context.lines[start[0]]
      change = ExtractI18n::SourceChange.new(
        i18n_key: "#{@file_key}.#{ExtractI18n.key(content)}",
        i18n_string: content,
        source_line: source_line,
        remove: item[:raw],
        t_template: @t_template,
        interpolation_type: :vue,
        interpolate_arguments: {},
      )

      if ExtractI18n.ignore?(change.i18n_string)
        return
      end
      token = Regexp.escape(item[:raw])
      regexp = Regexp.new(IGNORE_AFTER.to_s + token)
      return if source_line.match?(regexp)
      return if change.i18n_string[file_key]

      byte_from = @original_context.lines[0...start[0]].join.length + start[1]
      byte_to = @original_context.lines[0...finish[0]].join.length + finish[1]

      if @on_ask.call(change)
        byte_from += @byte_offset
        byte_to += @byte_offset

        @current_buffer = @current_buffer[0...byte_from] + change.i18n_t + @current_buffer[byte_to..]

        @byte_offset += change.i18n_t.length - item[:raw].length
      end
    end

    def vue2?(content)
      content['data()'] || content['computed:'] || content['this.$i18n'] || content['this.$t'] || content['this.$store']
    end
  end
end
