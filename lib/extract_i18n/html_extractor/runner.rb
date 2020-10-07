module ExtractI18
  module HTMLExtractor
    class Runner
      include Cli

      def initialize(args = {})
        @files = file_list_from_pattern(args[:file_pattern])
        @locale = args[:locale].presence
        @verbose = args[:verbose]
      end

      def run_interactive
        each_translation do |file, document, node|
          puts "Found \"#{node.text}\" in #{file}:#{node.text}".green
          next unless confirm 'Create a translation?', 'Yes', 'No', default: 'Yes'

          node.key = prompt 'Choose i18n key', default: node.key
          node.replace_text!

          document.save!(file)

          add_translations! node.key, node.text, default_locale: @locale
          puts
        end
      end

      def run
        each_translation do |file, document, node|
          puts "Found \"#{node.text}\" in #{file}:#{node.text}".green
          node.replace_text!
          document.save!(file)

          add_translation! I18n.default_locale, node.key, node.text
        end
      end

      def test_run
        each_translation do |file, _, node|
          puts "Found \"#{node.text}\" in #{file}:#{node.text}".green
        end
      end

      private

      def file_list_from_pattern(pattern)
        if pattern.present?
          Dir[Rails.root.join(pattern)]
        else
          Dir[Rails.root.join('app', 'views', '**', '*.erb')] -
            Dir[Rails.root.join('app', 'views', '**', '*.*.*.erb')]
        end
      end

      def add_translations!(key, text, default_locale: nil)
        return prompt_and_add_translation!(default_locale, key, default_text: text) if default_locale
        prompt_and_add_translation!(I18n.default_locale, key, default_text: text)

        I18n.available_locales.each do |locale|
          next if locale == I18n.default_locale

          prompt_and_add_translation!(locale.to_s, key)
        end
      end

      def prompt_and_add_translation!(locale, key, default_text: nil)
        out_text = prompt "Choose #{locale} value", default: default_text
        add_translation! locale, key, out_text
      end

      def add_translation!(locale, key, value)
        new_keys = i18n.missing_keys(locales: [locale]).set_each_value!(value)
        i18n.data.merge! new_keys
        puts "Added t(.#{key}), translated in #{locale} as #{value}:".green
        puts new_keys.inspect
      end

      def i18n
        I18n::Tasks::BaseTask.new
      end

      def each_translation
        @files.each do |file|
          document = I18n::HTMLExtractor::ErbDocument.parse file
          nodes_to_translate = extract_all_nodes_to_translate(document)
          nodes_to_translate.each { |node| yield(file, document, node) }
        end
      end

      def extract_all_nodes_to_translate(document)
        Match::Finder.new(document).matches
      end
    end
  end
end
