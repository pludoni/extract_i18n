# frozen_string_literal: true

module ExtractI18n
  class Slimkeyfy::SlimTransformer
    TRANSLATED = /t\s*\(?\s*(".*?"|'.*?')\s*\)?/.freeze
    STRING = /(\".*\"|\'.*\')/.freeze
    STRING_WITHOUT_QUOTES = /("(?<double_quot>.*)"|'(?<single_quot>.*)')/.freeze

    HTML_TAGS = /^(?<html_tag>'|\||([a-z\.]+[0-9\-]*)+)/.freeze
    EQUALS = /#?([a-z0-9\.\-\s]+)?\=.*/.freeze

    BEFORE =        /(?<before>.*)/.freeze
    TRANSLATION =   /(?<translation>(".*?"|'.*?'))/.freeze
    AFTER =         /(?<after>,?.*)?/.freeze

    HTML_ARGUMENTS = {
      hint: /(?<html_tag>hint:\s*)/,
      link_to: /(?<html_tag>link_to\s*\(?)/,
      inconified: /(?<html_tag>(iconified\s*\(?))/,
      placeholder: /(?<html_tag>placeholder:\s*)/,
      title: /(?<html_tag>title:\s*)/,
      prepend: /(?<html_tag>prepend:\s*)/,
      append: /(?<html_tag>append:\s*)/,
      label: /(?<html_tag>[a-z]*_?label:\s*)/,
      optionals: /(?<html_tag>(default|include_blank|alt):\s*)/,
      input: /(?<html_tag>[a-z]*\.?input:\s*)/,
      button: /(?<html_tag>[a-z]*\.?button:\s*(\:[a-z]+\s*,\s*)?)/,
      tag: /(?<html_tag>(submit|content)_tag[\:\(]?\s*)/,
      data_naive: /(?<html_tag>data:\s*\{\s*(confirm|content):\s*)/
    }.freeze

    LINK_TO = /#{HTML_ARGUMENTS[:link_to]}#{TRANSLATION}/.freeze

    def transform(&block)
      return yield(nil) if should_not_be_processed?(@word.as_list)
      unindented_line = @word.unindented_line

      if unindented_line.match(EQUALS)
        parse_html_arguments(unindented_line, &block)
      elsif @word.head.match(HTML_TAGS)
        parse_html(&block)
      else
        yield(nil)
      end
    end

    def initialize(word, file_key)
      @word = word
      @file_key = file_key
    end

    private

    def parse_html(&_block)
      return @word.line if @word.line.match(TRANSLATED)

      tagged_with_equals = Slimkeyfy::Whitespacer.convert_slim(@word.head)
      body = @word.tail.join(" ")
      body, tagged_with_equals = Slimkeyfy::Whitespacer.convert_nbsp(body, tagged_with_equals)

      if body.match(LINK_TO) != nil
        body = link_tos(body)
      end

      interpolate_arguments, body = extract_arguments(body)
      change = ExtractI18n::SourceChange.new(
        source_line: @word.line,
        remove: body,
        interpolate_arguments: interpolate_arguments,
        i18n_key: "#{@file_key}.#{ExtractI18n.key(body)}",
        i18n_string: body,
        t_template: "#{@word.indentation}#{tagged_with_equals} t('%s'%s)"
      )
      yield(change)
    end

    def parse_html_arguments(line, token_skipped_before = nil, &block)
      final_line = line
      regex_list.each do |regex|
        line.scan(regex) do |m_data|
          next if m_data == token_skipped_before
          before = m_data[0]
          html_tag = m_data[1]
          translation = match_string(m_data[2])
          after = m_data[3]
          interpolate_arguments, translation = extract_arguments(translation)
          change = ExtractI18n::SourceChange.new(
            source_line: @word.indentation + final_line,
            i18n_string: translation,
            i18n_key: "#{@file_key}.#{ExtractI18n.key(translation)}",
            remove: m_data[2],
            interpolate_arguments: interpolate_arguments,
            t_template: "#{before}#{html_tag}t('%s'%s)#{after}"
          )
          final_line = yield(change)
          return parse_html_arguments(final_line, &block)
        end
      end
      if final_line == line
        @word.indentation + final_line
      else
        final_line
      end
    end

    def link_tos(line)
      m = line.match(LINK_TO)
      if m != nil
        _ = m[:html_tag]
        translation = match_string(m[:translation])
        translation_key = update_hashes(translation)
        line = line.gsub(m[:translation], translation_key)
        link_tos(line)
      else
        line
      end
    end

    def should_not_be_processed?(tokens)
      (tokens.nil? or tokens.size < 2)
    end

    def matches_string?(translation)
      m = translation.match(STRING_WITHOUT_QUOTES)
      return false if m.nil?
      (m[:double_quot] != nil or m[:single_quot] != nil)
    end

    def match_string(translation)
      m = translation.match(STRING_WITHOUT_QUOTES)
      return translation if m.nil?
      if m[:double_quot] != nil
        m[:double_quot]
      else
        (m[:single_quot] != nil ? m[:single_quot] : translation)
      end
    end

    def regex_list
      HTML_ARGUMENTS.map { |_, regex| /#{BEFORE}#{regex}#{TRANSLATION}#{AFTER}/ }
    end

    def extract_arguments(translation)
      args = {}
      translation.scan(/\#{[^}]*}/).each_with_index do |arg, index|
        stripped_arg = arg[2..-2]
        key = ExtractI18n.key(arg)
        key += index.to_s if index > 0
        translation = translation.gsub(arg, "%{#{key}}")
        args[key] = stripped_arg
      end
      [args, translation]
    end
  end
end
