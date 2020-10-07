module ExtractI18n
  module HTMLExtractor
    module Match
      class PlainTextMatch < BaseMatch
        def self.create(document, node)
          return nil if node.name.start_with?('script')
          node.text.split(/\@\@(=?)[a-z0-9\-]+\@\@/).map! do |text|
            new(document, node, text.strip) if !text.nil? && !text.empty?
          end
        end

        def replace_text!(key, i18n_t)
          document.erb_directives[key] = i18n_t
          node.content = node.content.gsub(text, "@@=#{key}@@")
        end
      end
    end
  end
end
