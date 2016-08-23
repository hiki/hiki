# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hiki2yard/version'

Gem::Specification.new do |spec|
  spec.name          = "new_hiki"
  spec.version       = "0.1"
  spec.authors       = ["Shigeto R. Nishitani"]
  spec.email         = ["shigeto_nishitani@me.com"]

  spec.summary       = %q{Support making docs from hiki to yard, wiki, on gem development directory.}
  spec.description   = %q{Support making docs from hiki to yard, wiki, on gem development directory.}
  spec.homepage      = "https://github.com/daddygongon/new_hiki/wiki"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "hiki2md"
  spec.add_development_dependency "mathjax-yard"
end
