# frozen_string_literal: true

require 'parser/current'
require 'tty/prompt'
require 'diffy'
require 'yaml'

module ExtractI18n
  class FileProcessor
    PROMPT = TTY::Prompt.new
    PASTEL = Pastel.new

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
          # We are using a text extraction pipeline, so don't need this file
          # update_i18n_yml_file
          puts PASTEL.green("Saved #{@file_path}")
        end
      end
    end

    private

    def read_and_transform(&_block)
      key = if @options[:namespace]
              "#{@options[:namespace]}.#{@file_key}"
            else
              @file_key
            end
      adapter_class = ExtractI18n::Adapters::Adapter.for(@file_path)
      if adapter_class
        adapter = adapter_class.new(
          file_key: key,
          on_ask: ->(change) { ask_one_change?(change) },
          options: @options,
        )
        output = adapter.run(original_content)
        if output != original_content
          yield(output)
        end
      end
    end

    def ask_one_change?(change)
      check_for_unique!(change)
      puts change.format
      if PROMPT.no?("replace line ?")
        false
      else
        @i18n_changes[change.key] = change.i18n_string
        true
      end
    end

    def check_for_unique!(change)
      if @i18n_changes[change.key] && @i18n_changes[change.key] != change.i18n_string
        change.increment_key!
        check_for_unique!(change)
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
      @original_content ||= File.read(@file_path)
    end
  end
end
