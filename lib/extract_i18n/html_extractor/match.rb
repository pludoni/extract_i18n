module ExtractI18n
  module HTMLExtractor
    module Match
      class Finder
        attr_reader :document

        def initialize(document)
          @document = document
        end

        def matches
          erb_nodes(document) + plain_text_nodes(document) + form_fields(document)
        end

        private

        def erb_nodes(document)
          document.erb_directives.map do |fragment_id, _|
            ErbDirectiveMatch.create(document, fragment_id)
          end.flatten.compact
        end

        def plain_text_nodes(document)
          leaf_nodes.map! { |node| PlainTextMatch.create(document, node) }.flatten.compact
        end

        def form_fields(document)
          ExtractI18n.html_fields_with_plaintext.flat_map do |field|
            document.
              css("[#{field}]").
              select { |input| input[field] && !input[field].empty? }.
              reject { |n| n[field] =~ /\@\@(=?)[a-z0-9\-]+\@\@/ }.
              flat_map { |node| AttributeMatch.create(document, node, field) }
          end.compact
        end

        def leaf_nodes
          @leaf_nodes ||= document.css('*:not(:has(*))').select { |n| n.text && !n.text.empty? }
        end
      end
    end
  end
end
