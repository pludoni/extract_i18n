module ExtractI18n
  module HTMLExtractor
    module Match
      class BaseMatch < NodeMatch
        attr_reader :node

        def initialize(document, node, text)
          super(document, text)
          @node = node
        end

        def replace_text!
          node.content = translation_key_object
        end
      end
    end
  end
end
