require 'nokogiri'
module ExtractI18n::Adapters
  class VueAdapter < Adapter
    ATTRIBUTES_WITH_TEXT = %w[
      title
      alt
      placeholder
      label
      description
    ]
    def run(original_content)
      content2, replace_pairs = replace_camelcase_attributes(original_content)

      doc = Nokogiri::HTML5.fragment(content2)
      template = doc.at('template')
      return original_content unless template
      return original_content if template['lang']

      nodes = template.xpath(".//text() | text()").select { |i| i.to_s.strip.length > 0 }

      nodes.each do |node|
        process_change(node)
      end

      ATTRIBUTES_WITH_TEXT.each do |attr|
        template.search("*[#{attr}]").each do |node|
          process_attribute_change(node, attr)
        end
      end

      out = unreplace_camelcase_attributes(doc.to_s, replace_pairs)
      out.gsub!(/ (\w+)=""/) do |all_match|
        m = $1
        if original_content[/ #{m}[^=]/]
          " #{m}"
        else
          all_match
        end
      end
      @new_content = out.split("\n")
      check_javascript_for_strings!
      @new_content.join("\n")
    end

    # nokogir::html can parse @click.prevent stuff, but transforms all CamelCase Attributes to kebab-case by default
    # To keep the original case, we replace it with a placeholder and unreplace it back
    def replace_camelcase_attributes(text)
      cc = 1
      pairs = []
      replaced = text.gsub(/ ([a-zA-Z:]+=)/) { |pp|
        match = Regexp.last_match
        cc += 1
        # kebab-case
        if pp[/[A-Z]/]
          kebab = match[1].gsub(/([A-Z])/) { |i| "-#{i.downcase}" }
          hack = " :camelcase-nokogiri-hack-#{cc}-#{kebab}"
          pairs << [hack, " " + match[1]]
          hack
        else
          pp
        end
      }
      # tags
      replaced.scan(/<([a-zA-Z0-9]+)/).flatten.each do |pp|
        next pp unless pp[/[A-Z]/]

        cc += 1

        kebab = pp.gsub(/([A-Z])/) { |i| "-#{i.downcase}" }.sub(/^-/, '')
        hack = "camelcase-nokogiri-hack-#{cc}-#{kebab}"
        replaced.gsub!(/<#{pp}/, "<#{hack}")
        replaced.gsub!(/<\/ *#{pp}/, "</#{hack}")
        pairs << ["<#{hack}", "<#{pp}"]
        pairs << ["</#{hack}", "</#{pp}"]
      end
      [replaced, pairs]
    end

    def unreplace_camelcase_attributes(text, pairs)
      txt = text.dup
      pairs.each do |hack, camel|
        txt.gsub!(hack, camel)
      end
      txt
    end

    def process_attribute_change(node, attr)
      _, ws_before, content, ws_after = node[attr].to_s.match(/(\s*)(.*?)(\s*)$/m).to_a

      interpolate_arguments, content = extract_arguments(content)

      change = ExtractI18n::SourceChange.new(
        i18n_key: "#{@file_key}.#{ExtractI18n.key(content)}",
        i18n_string: content,
        source_line: node.to_s,
        remove: content,
        t_template: %[$t('%s'%s)],
        interpolation_type: :vue,
        interpolate_arguments: interpolate_arguments,
      )
      if @on_ask.call(change)
        node.remove_attribute "title"
        node[":" + attr] = "#{ws_before}#{change.i18n_t}#{ws_after}"
      end
    end

    def process_change(node)
      _, ws_before, content, ws_after = node.to_s.match(/(\s*)(.*?)(\s*)$/m).to_a

      return if content[/^\{\{/]

      interpolate_arguments, content = extract_arguments(content)

      change = ExtractI18n::SourceChange.new(
        i18n_key: "#{@file_key}.#{ExtractI18n.key(content)}",
        i18n_string: content,
        source_line: node.parent.to_s,
        remove: content,
        t_template: %[{{ $t('%s'%s) }}],
        interpolation_type: :vue,
        interpolate_arguments: interpolate_arguments,
      )
      if @on_ask.call(change)
        node.replace("#{ws_before}#{change.i18n_t}#{ws_after}")
      end
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

    def check_javascript_for_strings!
      lines = @new_content
      # drop lines until <script
      start = lines.find_index { |line| line[/^<script/] }
      finish = lines.find_index { |line| line[/^<\/script/] }
      return if start.nil? || finish.nil?

      js_content = lines[(start + 1)...finish].join("\n")

      js_adapter = ExtractI18n::Adapters::JsAdapter.new(file_key: @file_key, on_ask: @on_ask, options: @options)
      js_replaced = js_adapter.run(js_content)

      @new_content = lines[0..start] + js_replaced.split("\n") + lines[(finish)..-1]
    end
  end
end
