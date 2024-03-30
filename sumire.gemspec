# frozen_string_literal: true

require_relative "lib/sumire/version"

Gem::Specification.new do |spec|
  spec.name = "sumire"
  spec.version = Sumire::VERSION
  spec.authors = ["MURATA Mitsuharu"]
  spec.email = ["hikari.photon+dev@gmail.com"]

  spec.summary = "Monitor the `script` command and add the recorded time."
  spec.description = spec.summary
  spec.homepage = "https://github.com/Himeyama/sumire"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ansi2txt", "~> 24.03.29"
  spec.add_dependency "listen", "~> 3.9.0"
  spec.add_dependency "sys-proctable", "~> 1.3"
end
