# frozen_string_literal: true

module ExtractI18n
  class Slimkeyfy::Whitespacer
    HTML = /([a-z\.]+[0-9\-]*)+/.freeze
    HTML_TAGS = /^(?<html_tag>'|\||#{HTML})/.freeze

    def self.convert_slim(string)
      m = string.match(HTML_TAGS)

      return string if m.nil? or m[:html_tag].nil?
      return string if has_equals_tag?(string, m[:html_tag])
      tag = m[:html_tag]

      case tag
      when /\|/
        string.gsub("|", "=")
      when /\'/
        string.gsub("'", "=>")
      when HTML
        string.gsub(string, "#{string} =")
      else string end
    end

    def self.convert_nbsp(body, tag)
      lead = leading_nbsp(body)
      trail = trailing_nsbp(body, tag)

      tag = tag.gsub(tag, "#{tag}#{lead}#{trail}")
      [body.sub(/^&nbsp;/, '').sub(/&nbsp;$/, '').gsub("&nbsp;", " "), tag.gsub("=><", "=<>")]
    end

    def self.leading_nbsp(body)
      return "<" if body.start_with?("&nbsp;")
    end

    def self.trailing_nsbp(body, tag)
      return '' if tag.start_with?("=>")
      return ">" if body.end_with?("&nbsp;")
    end

    def self.has_equals_tag?(string, html_tag)
      string.gsub(html_tag, "").strip.start_with?("=")
    end
  end
end
