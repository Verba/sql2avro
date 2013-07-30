Gem::Specification.new do |spec|
  spec.name        = 'sql2avro'
  spec.summary     = "Tool for pulling data from SQL database tables into Avro files."
  spec.description = "sql2avro extracts data from a specified SQL database table and transforms it into an Avro file with a schema based on the database table's schema. The intended use case is to incrementally load data out of an SQL database and into HDFS for analysis via Hadoop."
  spec.version     = "0.5.0"
  spec.authors     = ['Mason Simon']
  spec.email       = ['mason@verbasoftware.com']

  spec.files       = Dir['lib/**/*', 'test/**/*', 'vendor/*', 'Makefile']
  spec.homepage    = 'https://github.com/Verba/sql2avro'
  spec.has_rdoc    = false
  spec.license     = "Apache 2.0"

  spec.add_dependency "yajl-ruby"
end

