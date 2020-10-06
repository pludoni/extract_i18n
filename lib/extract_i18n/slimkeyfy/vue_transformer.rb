# frozen_string_literal: true

class ExtractI18n::Slimkeyfy::VueTransformer < ExtractI18n::Slimkeyfy::SlimTransformer
  BEFORE = /(?<before>.*[\( ^])/.freeze
  HTML_ARGUMENTS = {
    placeholder: /(?<html_tag>[a-z\-]*placeholder=\s*)/,
    title: /(?<html_tag>title=\s*)/,
    kind_of_title: /(?<html_tag>[a-z\-]+title=\s*)/,
    label: /(?<html_tag>[a-z\-]*label=\s*)/,
    description: /(?<html_tag>description=\s*)/,
    alt: /(?<html_tag>alt=\s*)/,
    prepend: /(?<html_tag>prepend=\s*)/,
    append: /(?<html_tag>append=\s*)/,
  }.freeze

  def regex_list
    HTML_ARGUMENTS.map { |_, regex| /#{BEFORE}#{regex}#{TRANSLATION}#{AFTER}/ }
  end

  def parse_html(&_block)
    return @word.line if @word.line.match(TRANSLATED)
    return @word.line if @word.tail.join(" ")[/^{{.*}}$/]

    body = @word.tail.join(" ")
    body, tagged_with_equals = ExtractI18n::Slimkeyfy::Whitespacer.convert_nbsp(body, @word.head)

    tagged_with_equals = "|" if tagged_with_equals == "="

    interpolate_arguments, body = extract_arguments(body)

    change = ExtractI18n::SourceChange.new(
      source_line: @word.line,
      remove: body,
      interpolate_arguments: interpolate_arguments,
      interpolation_type: :vue,
      i18n_key: "#{@file_key}.#{ExtractI18n.key(body)}",
      i18n_string: body,
      t_template: "#{@word.indentation}#{tagged_with_equals} {{ $t('%s'%s) }}"
    )
    yield(change)
  end

  def parse_html_arguments(line, token_skipped_before = nil, &block)
    final_line = line
    regex_list.each do |regex|
      line.scan(regex) do |m_data|
        next if m_data == token_skipped_before
        before = m_data[0]
        if before[-1] == ":" # already dynamic attribute
          next
        end
        html_tag = m_data[1]
        translation = match_string(m_data[2])
        after = m_data[3]
        interpolate_arguments, translation = extract_arguments(translation)

        change = ExtractI18n::SourceChange.new(
          source_line: final_line,
          i18n_string: translation,
          i18n_key: "#{@file_key}.#{ExtractI18n.key(translation)}",
          remove: m_data[2],
          interpolate_arguments: interpolate_arguments,
          interpolation_type: :vue,
          t_template: "#{before}:#{html_tag}\"$t('%s'%s)\"#{after}"
        )
        final_line = yield(change)
        return parse_html_arguments(final_line, m_data, &block)
      end
    end
    @word.indentation + final_line
  end

  def extract_arguments(translation)
    args = {}
    translation.scan(/\{\{([^}]*)\}\}/).each_with_index do |stripped_arg, index|
      arg = Regexp.last_match[0]
      key = ExtractI18n.key(arg)
      key = key + index.to_s if index > 0
      translation = translation.gsub(arg, "{#{key}}")
      args[key] = stripped_arg[0]
    end
    [args, translation]
  end
end
