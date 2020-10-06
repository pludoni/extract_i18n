# frozen_string_literal: true

require 'parser/current'
require 'tty/prompt'
require 'diffy'

module ExtractI18n
  class FileProcessor
    PROMPT = TTY::Prompt.new

    def initialize(file_path:, write_to:, locale:, options: {})
      @file_path = file_path
      @file_key = ExtractI18n.file_key(@file_path)

      @locale = locale
      @write_to = write_to
      @options = options
      @i18n_changes = {}
    end

    def run
      puts " reading #{@file_path}"
      read_and_transform do |result|
        puts Diffy::Diff.new(original_content, result, context: 1).to_s(:color)
        if PROMPT.yes?("Save changes?")
          File.write(@file_path, result)
          update_i18n_yml_file(i18n_changes)
          puts PASTEL.green("Saved #{@file_path}")
        end
      end
    end

    private

    def read_and_transform(&block)
      if @options[:namespace]
        key = "#{@options[:namespace]}.#{@file_key}"
      else
        key = @file_key
      end
      adapter_class = ExtractI18n::Adapters::Adapter.for(@file_path)
      if @options[:relative] && adapter_class.supports_relative_keys?
        key = ""
      end
      if adapter_class
        adapter = adapter_class.new(
          file_key: key,
          on_ask: ->(change) { ask_one_change?(change) },
          options: @options
        )
        output = adapter.run(original_content)
        if output != original_content
          yield(output)
        end
      end
    end

    def ask_one_change?(change)
      puts change.format
      if PROMPT.no?("replace line ?")
        @i18n_changes[change.key] = change.i18n_string
        true
      else
        false
      end
    end

    def update_i18n_yml_file
      base = if File.exist?(@write_to)
               YAML.load_file(@write_to)
             else
               {}
             end
      @i18n_changes.each do |key, value|
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
  end
end
