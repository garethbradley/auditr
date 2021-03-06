# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'auditr/version'

Gem::Specification.new do |spec|
  spec.name          = "auditr"
  spec.version       = Auditr::VERSION
  spec.authors       = ["Gareth Bradley"]
  spec.email         = ["gb@garethbradley.co.uk"]
  spec.description   = "An auditing gem that allows notes to be saved against models"
  spec.summary       = "An auditing gem that allows notes to be saved against models"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
