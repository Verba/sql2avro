Gem::Specification.new do |spec|
  spec.name        = 'sql2avro'
  spec.summary     = "Avroizes data from a SQL database."
  spec.version     = "0.1.0"
  spec.authors     = ['Mason Simon']
  spec.email       = ['mason@verbasoftware.com']

  spec.files       = Dir['lib/**/*', 'test/**/*', 'vendor/*', 'Makefile']
  spec.homepage    = ''
  spec.has_rdoc    = false
  spec.license     = "Apache 2.0"

  spec.add_dependency "yajl-ruby"
end

