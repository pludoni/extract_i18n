require 'nokogiri'

module ExtractI18n
  module HTMLExtractor
    class ErbDocument
      ERB_REGEXPS = [
        TwoWayRegexp.new(/<%=(?<inner_text>.+?)%>/m, /@@=(?<inner_text>[a-z0-9\-\._]+)@@/m),
        TwoWayRegexp.new(/<%#(?<inner_text>.+?)%>/m, /@@#(?<inner_text>[a-z0-9\-\._]+)@@/m),
        TwoWayRegexp.new(/<%(?<inner_text>.+?)%>/m, /@@(?<inner_text>[a-z0-9\-\._]+)@@/m)
      ].freeze

      attr_reader :erb_directives

      def initialize(document, erb_directives)
        @document = document
        @erb_directives = erb_directives
      end

      def save
        result = @document.to_html(indent: 2, encoding: 'UTF-8')
        ERB_REGEXPS.each do |regexp|
          regexp.inverse_replace!(result) do |string_format, data|
            string_format % { inner_text: erb_directives[data[:inner_text]] }
          end
        end
        result
      end

      def method_missing(name, *args, &block)
        @document.public_send(name, *args, &block) if @document.respond_to? name
      end

      class <<self
        def parse(filename, verbose: false)
          file_content = ''
          File.open(filename) do |file|
            file.read(nil, file_content)
            return parse_string(file_content, verbose: verbose)
          end
        end

        def parse_string(string, verbose: false)
          erb_directives = extract_erb_directives! string
          document = create_document(string)
          log_errors(document.errors, string) if verbose
          ErbDocument.new(document, erb_directives)
        end

        private

        def create_document(file_content)
          if file_content.start_with?('<!DOCTYPE')
            Nokogiri::HTML(file_content)
          else
            Nokogiri::HTML.fragment(file_content)
          end
        end

        def log_errors(errors, file_content)
          return if errors.empty?
          text = file_content.split("\n")
          errors.each do |e|
            puts "Error at line #{e.line}: #{e}".red
            puts text[e.line - 1]
          end
        end

        def extract_erb_directives!(text)
          erb_directives = {}

          ERB_REGEXPS.each do |regexp|
            regexp.replace!(text) do |string_format, data|
              key = SecureRandom.uuid
              erb_directives[key] = data[:inner_text]
              string_format % { inner_text: key }
            end
          end
          erb_directives
        end
      end
    end
  end
end
