require 'optparse'
require 'extract_i18n/file_processor'
require 'extract_i18n/version'
require 'open-uri'

module ExtractI18n
  # Cli Class
  class CLI
    def initialize
      @options = {}
      ARGV << '-h' if ARGV.empty?
      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} -l <locale> -w <target-yml> [path*]"

        opts.on('--version', 'Print version number') do
          puts ExtractI18n::VERSION
          exit
        end

        opts.on('-lLOCALE', '--locale=LOCALE', 'default locale for extraction (Default = en)') do |f|
          @options[:locale] = f || 'en'
        end

        opts.on('-wYAML', '--write=YAML-FILE', 'Write extracted keys to YAML file (default = config/locales/unsorted.LOCALE.yml)') do |f|
          @options[:write_to] = f || "config/locales/unsorted.#{@options[:locale]}"
        end

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end.parse!

      @files = ARGV
    end

    def run
      paths = @files.empty? ? [] : @files
      paths.each do |path|
        if File.directory?(path)
          glob_path = File.join(path, '**', '*.rb')
          Dir.glob(glob_path) do |file_path|
            process_file file_path
          end
        else
          process_file path
        end
      end
    end

    def process_file(file_path)
      puts "Processing: #{file_path}"
      ExtractI18n::Processor.new(
        file_path: file_path,
        write_to: @options[:write_to],
        locale: @options[:locale],
        options: @options,
      ).run
    end
  end
end
