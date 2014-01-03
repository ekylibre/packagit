# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'packagit/version'

Gem::Specification.new do |spec|
  spec.name          = "packagit"
  spec.version       = Packagit::VERSION
  spec.authors       = ["Brice Texier"]
  spec.email         = ["burisu@oneiros.fr"]
  spec.description   = %q{Build packages}
  spec.summary       = %q{Build packages}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files LICENSE.txt README.md lib bin`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "> 2.3"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
