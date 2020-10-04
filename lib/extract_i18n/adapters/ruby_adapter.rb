module ExtractI18n::Adapters
  class RubyAdapter < Adapter
    def run(original_content)
      buffer        = Parser::Source::Buffer.new('(example)')
      buffer.source = original_content
      temp = Parser::CurrentRuby.parse(original_content)
      rewriter = ExtractI18n::Rewriter.new(
        file_key: file_key,
        on_ask: on_ask
      )
      # Rewrite the AST, returns a String with the new form.
      rewriter.rewrite(buffer, temp)
      # rescue StandardError => e
      #   puts 'Parsing error'
      #   puts e.inspect
    end
  end
end
