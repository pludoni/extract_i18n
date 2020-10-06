# frozen_string_literal: true

require 'slim'

module ExtractI18n::Adapters
  class SlimAdapterWip < Adapter
    def run(original_content)
      parser = SlimRewriterParser.new(file_key: file_key, on_ask: on_ask)
      parser.call(original_content)
    end
  end

  class SlimRewriterParser < Slim::Engine
    class CustomFilter < Slim::Filter
      define_options file_key: :dynamic, on_ask: :dynamic
      def call(exp)
        @indent = 0
        super.to_s
      end

      def on_multi(*exps)
        super[1..-1].join
      end

      def on_newline
        "\n"
      end

      def on_static(*args)
        args[0].include?('"') ? "'#{args.join(' ')}'" : %["#{args.join(' ')}"]
      end

      def on_html_doctype(name)
        "#{indent}doctype #{name}"
      end

      def on_html_tag(name, attrs, content = nil)
        ret = "#{indent}#{name}#{compile attrs}"
        if content
          ret << ' ' << block(content)
        end
        ret
      end

      def block(content)
        @indent += 1
        result = compile(content).to_s # todo remove to_s
        if result.is_a?(String)
          extract_from_string(result)
        else
          result
        end
      ensure
        @indent -= 1
      end

      def extract_from_string(string)
        i18n_key = ExtractI18n.key(string)
        change = ExtractI18n::SourceChange.new(
          i18n_key: "#{@options[:file_key]}.#{i18n_key}",
          i18n_string: string,
          interpolate_arguments: {},
          source_line: string,
          remove: string
        )
        puts change.format
        if @options[:on_ask].call(change)
          change.i18n_t
        else
          string
        end
      end

      def on_html_attrs(*attrs)
        attrs.empty? ? '' : "(#{super[2..-1].join(' ')})"
      end

      def on_slim_interpolate(text)
        compile(text)
      end

      def on_slim_text(type, text)
        block(text)
      end

      def on_slim_embedded(type, text)
        "#{indent}#{block text}"
      end

      def on_html_comment(exp)
        "#{indent}/ #{block exp}"
      end

      def on_slim_control(line, block)
        "#{indent}- #{line}#{block block}"
      end

      def on_html_attr(name, content)
        "#{name}=#{compile content}"
      end

      def indent
        '  ' * @indent
      end

      # def parse_text_block(first_line = nil, text_indent = nil)
      #   source_line = @_lines[@lineno - 1]

      #   binding.pry
      #   result = super

      #   change = ExtractI18n::SourceChange.new(
      #     i18n_key: "#{@file_key}.#{i18n_key}",
      #     i18n_string: i18n_string,
      #     interpolate_arguments: {},
      #     source_line: source_line,
      #     remove: node.loc.expression.source
      #   )
      #   binding.pry

      #   result
      # end
    end
    remove //
    filter :Encoding
    filter :RemoveBOM
    use Slim::Parser
    use CustomFilter
  end
end
