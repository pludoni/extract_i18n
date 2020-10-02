lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "extract_i18n/version"

Gem::Specification.new do |spec|
  spec.name          = "extract_i18n"
  spec.version       = ExtractI18n::VERSION
  spec.authors       = ["Stefan Wienert"]
  spec.email         = ["info@stefanwienert.de"]

  spec.summary       = %q{Extact i18n from RUBY Files using Ruby parser}
  spec.description   = %q{Extact i18n from RUBY Files using Ruby parser}
  spec.homepage      = "https://github.com/pludoni/extract_i18n"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'parser', '>= 2.6'
  spec.add_runtime_dependency 'tty-prompt'
  spec.add_dependency "diff-lcs"
  spec.add_dependency "diffy"
end
