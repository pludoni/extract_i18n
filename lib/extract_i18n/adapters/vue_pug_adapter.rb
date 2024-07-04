# frozen_string_literal: true

module ExtractI18n::Adapters
  class VuePugAdapter < SlimAdapter
    def run(original_content)
      super
      check_javascript_for_strings!
      @new_content.join("\n")
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

    def process_line(old_line)
      @mode ||= :template
      if old_line[/^<template/]
        @mode = :template
      elsif old_line[/^<script/]
        @mode = :script
      elsif old_line[/^<style/]
        @mode = :style
      end
      if @mode != :template
        return old_line
      end
      word = ExtractI18n::Slimkeyfy::Word.for('.vue').new(old_line)
      ExtractI18n::Slimkeyfy::VueTransformer.new(word, @file_key).transform do |change|
        if change.nil? # nothing to do
          return old_line
        end
        if ExtractI18n.ignore?(change.i18n_string) || change.i18n_string.empty?
          return old_line
        end

        if @on_ask.call(change)
          change.i18n_t
        else
          old_line
        end
      end
    end
  end
end
