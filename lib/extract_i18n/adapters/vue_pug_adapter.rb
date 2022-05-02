# frozen_string_literal: true

module ExtractI18n::Adapters
  class VuePugAdapter < SlimAdapter
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

        if @on_ask.call(change)
          change.i18n_t
        else
          old_line
        end
      end
    end
  end
end
