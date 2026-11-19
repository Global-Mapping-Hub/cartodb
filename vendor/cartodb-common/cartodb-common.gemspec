Gem::Specification.new do |spec|
  spec.name = 'cartodb-common'
  spec.version = '0.3.7'
  spec.authors = ['CARTO']
  spec.email = ['support@carto.com']
  spec.summary = 'Shared CARTO logger, job logger, and password hashing helpers'
  spec.license = 'BSD-3-Clause'
  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.4'

  spec.add_dependency 'activesupport', '>= 7.2'
  spec.add_dependency 'argon2', '~> 2.0'
end
