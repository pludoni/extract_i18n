module ExtractI18n::Adapters
  class Adapter
    def self.for(file_path)
      case file_path
      when /\.rb$/ then RubyAdapter
      end
    end

    attr_reader :on_ask, :file_path, :file_key, :options

    def initialize(file_key:, on_ask:, options: {})
      @on_ask = on_ask
      @file_key = file_key
      @options = options
    end

    def run(content)
      raise NotImplementedError
    end

    private

    def original_content
      @original_content ||= File.read(file_path)
    end
  end
end
