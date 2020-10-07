module ExtractI18n
  module HTMLExtractor
    class TwoWayRegexp
      attr_reader :from, :to

      def initialize(from, to)
        @from = from
        @to = to
      end

      def replace(text)
        if block_given?
          text.gsub(@from) do |matched_text|
            yield(to_as_format, Regexp.last_match, matched_text)
          end
        else
          text.gsub(@from, reverse_to)
        end
      end

      def replace!(text)
        if block_given?
          text.gsub!(@from) do |matched_text|
            yield(to_as_format, Regexp.last_match, matched_text)
          end
        else
          text.gsub!(@from, reverse_to)
        end
      end

      def inverse_replace(text)
        if block_given?
          text.gsub(@to) do |matched_text|
            yield(from_as_format, Regexp.last_match, matched_text)
          end
        else
          text.gsub(@to, reverse_from)
        end
      end

      def inverse_replace!(text)
        if block_given?
          text.gsub!(@to) do |matched_text|
            yield(from_as_format, Regexp.last_match, matched_text)
          end
        else
          text.gsub!(@to, reverse_from)
        end
      end

      private

      def to_as_format
        @to_as_format ||= @to.source.gsub('%', '%%').gsub!(/\(\?<([a-z_]+)>.*\)/, '%{\1}')
      end

      def from_as_format
        @from_as_format ||= @from.source.gsub('%', '%%').gsub!(/\(\?<([a-z_]+)>.*\)/, '%{\1}')
      end

      def reverse_from
        @reverse_from ||= @from.source.gsub(/\(\?<([a-z_]+)>.*\)/, '\k{\1}')
      end

      def reverse_to
        @reverse_to ||= @to.source.gsub(/\(\?<([a-z_]+)>.*\)/, '\k{\1}')
      end
    end
  end
end
