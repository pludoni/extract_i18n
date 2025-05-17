module ExtractI18n
  module HTMLExtractor
    module Match
      class NodeMatch
        attr_reader :document, :text

        def initialize(document, text)
          @document = document
          @text = text
        end

        def translation_key_object
          "t('.#{key}')"
        end

        def replace_text!
          raise NotImplementedError
        end

        def to_s
          text
        end

        attr_writer :key

        def key
          @key ||= text.parameterize.underscore
        end
      end
    end
  end
end
