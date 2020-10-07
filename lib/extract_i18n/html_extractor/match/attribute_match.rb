module ExtractI18n
  module HTMLExtractor
    module Match
      class AttributeMatch < BaseMatch
        def initialize(document, node, text, attribute)
          super(document, node, text)
          @attribute = attribute
        end

        def self.create(document, node, attribute)
          if node[attribute] && !node[attribute].empty?
            [new(document, node, node[attribute], attribute)]
          else
            []
          end
        end

        def replace_text!(key, i18n_t)
          document.erb_directives[key] = i18n_t
          node[@attribute] = "@@=#{key}@@"
        end
      end
    end
  end
end
