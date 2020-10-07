module ExtractI18n
  module HTMLExtractor
    module Match
      class ErbDirectiveMatch < NodeMatch
        REGEXPS = [
          [/^([ \t]*link_to )(("[^"]+")|('[^']+'))/, '\1%s', 2],
          [/^([ \t]*link_to (.*),[ ]?title:[ ]?)(("[^"]+")|('[^']+'))/, '\1%s', 3],
          [/^([ \t]*[a-z_]+\.[a-z_]+_field (.*),[ ]?placeholder:[ ]?)(("[^"]+")|('[^']+'))/, '\1%s', 3],
          [/^([ \t]*[a-z_]+\.text_area (.*),[ ]?placeholder:[ ]?)(("[^"]+")|('[^']+'))/, '\1%s', 3],
          [/^([ \t]*[a-z_]+\.submit )(("[^"]+")|('[^']+'))/, '\1%s', 2],
          [/^([ \t]*[a-z_]+\.label\s+\:[a-z_]+\,\s+)(("[^"]+")|('[^']+'))/, '\1%s', 2]
        ].freeze

        def initialize(document, fragment_id, text, regexp)
          super(document, text)
          @fragment_id = fragment_id
          @regexp = regexp
        end

        def replace_text!(key, i18n_t)
          document.erb_directives[@fragment_id].gsub!(@regexp[0], @regexp[1] % i18n_t.strip)
        end

        def self.create(document, fragment_id)
          REGEXPS.map do |r|
            match = document.erb_directives[fragment_id].match(r[0])
            new(document, fragment_id, match[r[2]][1...-1], r) if match && match[r[2]]
          end
        end
      end
    end
  end
end
