# frozen_string_literal: true

require "extract_i18n/version"

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "html_extractor"   => "HTMLExtractor",
)
loader.setup # ready!

module ExtractI18n
  class << self
    attr_accessor :strip_path, :ignore_hash_keys, :ignore_functions, :ignorelist, :html_fields_with_plaintext
  end

  self.strip_path = %r{^app/(javascript|controllers|views)|^lib|^src|^app}

  # ignore for .rb files: ignore those file types
  self.ignore_hash_keys = %w[class_name foreign_key join_table association_foreign_key key]
  self.ignore_functions = %w[where order group select sql]
  self.ignorelist = [
    '_',
    '::',
    %r{^/}
  ]
  self.html_fields_with_plaintext = %w[title placeholder alt label aria-label modal-title]

  def self.key(string, length: 25)
    string.strip.
      unicode_normalize(:nfkd).gsub(/(\p{Letter})\p{Mark}+/, '\\1').
      gsub(/\W+/, '_').downcase[0..length].
      gsub(/_+$|^_+/, '')
  end

  def self.file_key(path)
    path.gsub(strip_path, '').
      gsub(%r{^/|/$}, '').
      gsub(/\.(vue|rb|html\.slim|\.slim)$/, '').
      gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').
      gsub('/_', '.').
      gsub('/', '.').
      tr("-", "_").downcase
  end
end

require 'extract_i18n/file_processor'
