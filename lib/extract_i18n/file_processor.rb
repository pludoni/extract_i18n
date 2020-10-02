require 'extract_i18n/transform'
require 'parser/current'
require 'diffy'

module ExtractI18n
  class FileProcessor
    PROMPT = TTY::Prompt.new

    def initialize(file_path:, write_to:, locale:)
      @file_path = file_path
      @file_key = @file_path.gsub(%r{^app/|\.rb|^lib/$}, '').gsub('/', '.')
      @locale = locale
      @write_to = write_to
    end

    def run
      puts " reading #{@file_path}"
      read_and_transform do |result, i18n_changes|
        puts Diffy::Diff.new(original_content, result, context: 1).to_s(:color)
        if PROMPT.yes?("Save changes?")
          File.write(@file_path, result)
          update_i18n_yml_file(i18n_changes)
          puts PASTEL.green("Saved")
        end
      end
    end

    private

    def update_i18n_yml_file(i18n_changes)
      base = if File.exist?(@write_to)
               YAML.load_file(@write_to)
             else
               {}
             end
      i18n_changes.each do |key, value|
        tree = base
        keys = key.split('.').unshift(@locale)
        keys.each_with_index do |part, i|
          if i == keys.length - 1
            tree[part] = value
          else
            tree = tree[part] ||= {}
          end
        end
      end
      File.write(@write_to, base.to_yaml)
    end

    def original_content
      @original_content ||= File.read(file_path)
    end

    def read_and_transform(&block)
      buffer        = Parser::Source::Buffer.new('(example)')
      buffer.source = original_content
      begin
        temp = Parser::CurrentRuby.parse(original_content)
        rewriter = ExtractI18n::Transform.new(file_key: @file_key)

        # Rewrite the AST, returns a String with the new form.
        output = rewriter.rewrite(buffer, temp)
        if output != original_content
          yield(output, rewriter.i18n_changes)
        end
      rescue StandardError => e
        puts 'Parsing error'
        puts e.inspect
        nil
      end
    end
  end
end
