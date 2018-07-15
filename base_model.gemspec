
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'base_model/version'

Gem::Specification.new do |spec|
  spec.name          = 'base_model'
  spec.version       = BaseModel::VERSION
  spec.authors       = ['Jurgens du Toit']
  spec.email         = ['jrgns@aex.co.za']

  spec.summary       = %q{A set of Models that act like Sequel::Model but operate on files, APIs and maybe more.}
  spec.description   = %q{A set of Models that act like Sequel::Model but operate on files, APIs and maybe more.}
  spec.homepage      = 'https://github.com/EagerELK/base_model'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
