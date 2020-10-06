require 'parser/current'
require 'tty-prompt'
require 'pry'
require 'pastel'
require 'yaml'
require 'extract_i18n/source_change'

module ExtractI18n::Adapters
  class RubyAdapter < Adapter
    def run(original_content)
      buffer        = Parser::Source::Buffer.new('(example)')
      buffer.source = original_content
      temp = Parser::CurrentRuby.parse(original_content)
      rewriter = ExtractI18n::Adapters::Rewriter.new(
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

  class Rewriter < Parser::TreeRewriter
    PROMPT = TTY::Prompt.new
    PASTEL = Pastel.new

    def initialize(file_key:, on_ask:)
      @file_key = file_key
      @on_ask = on_ask
    end

    def process(node)
      @nesting ||= []
      @nesting.push(node)
      super
      @nesting.pop
    end

    def on_dstr(node)
      if ignore?(node, parent: @nesting[-2])
        return
      end
      interpolate_arguments = {}
      out_string = ""
      node.children.each do |i|
        if i.type == :str
          out_string += i.children.first
        else
          inner_source = i.children[0].loc.expression.source.gsub(/^#\{|}$/, '')
          interpolate_key = ExtractI18n.key(inner_source)
          out_string += "%{#{interpolate_key}}"
          interpolate_arguments[interpolate_key] = inner_source
        end
      end

      i18n_key = ExtractI18n.key(node.children.select { |i| i.type == :str }.map { |i| i.children[0] }.join(' '))

      ask_and_continue(i18n_key: i18n_key, i18n_string: out_string, interpolate_arguments: interpolate_arguments, node: node)
    end

    def on_str(node)
      string = node.children.first
      if ignore?(node, parent: @nesting[-2])
        return
      end
      ask_and_continue(i18n_key: ExtractI18n.key(string), i18n_string: string, node: node)
    end

    private

    def ask_and_continue(i18n_key:, i18n_string:, interpolate_arguments: {}, node:)
      change = ExtractI18n::SourceChange.new(
        i18n_key: "#{@file_key}.#{i18n_key}",
        i18n_string: i18n_string,
        interpolate_arguments: interpolate_arguments,
        source_line: node.location.expression.source_line,
        remove: node.loc.expression.source
      )
      if @on_ask.call(change)
        replace_content(node, change.i18n_t)
      end
    end

    def log(string)
      puts string
    end

    def replace_content(node, content)
      if node.loc.is_a?(Parser::Source::Map::Heredoc)
        replace(node.loc.expression.join(node.loc.heredoc_end), content)
      else
        replace(node.loc.expression, content)
      end
    end

    def ignore?(node, parent: nil)
      unless node.respond_to?(:children)
        return false
      end
      if parent && ignore_parent?(parent)
        return true
      end
      if node.type == :str
        ExtractI18n.ignorelist.any? { |item| node.children[0][item] }
      else
        node.children.any? { |child|
          ignore?(child)
        }
      end
    end

    def ignore_parent?(node)
      node.children[1] == :require ||
        node.type == :regexp ||
        (node.type == :pair && ExtractI18n.ignore_hash_keys.include?(node.children[0].children[0].to_s)) ||
        (node.type == :send && ExtractI18n.ignore_functions.include?(node.children[1].to_s))
    end
  end
end
