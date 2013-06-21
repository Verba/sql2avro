require 'open3'
require 'yaml'
require 'yajl'
require_relative 'interface/mysql'

module Sql2Avro
  AVRO_TOOLS_PATH = File.expand_path('../../vendor/avro-tools-1.7.4.jar', __FILE__)


  # Pulls data from the given database table starting from the given id.
  #
  # This function creates an Avro file as a side effect, and returns {
  #   max_id: greatest ID that was pulled in,
  #   path: filepath of the resulting avroized file
  #   error: error message, if any; otherwise omitted
  # }
  #
  # database_config is a hash with this form (like ActiveRecord's):
  # {
  #   adapter:  "mysql",
  #   host:     "localhost",
  #   username: "myuser",
  #   password: "mypass",
  #   database: "somedatabase"
  # }
  #
  # table is the table to pull from.
  #
  # min_id specifies the value of the id column from which to start.
  def Sql2Avro.avroize(database_config, table, min_id)
    raise "Database interface not specified." if !database_config.has_key? 'adapter'
    raise "Database interface not supported: #{database_config['adapter']}" if database_config['adapter'] != 'mysql'

    interface = MySql.new(database_config)

    schema = Yajl::Encoder.encode(interface.schema(table))
    max_id = interface.max_id(table)

    date, time, zone = Time.now.utc.to_s.split
    filename = "#{table}.#{date}T#{time}Z.#{min_id}.#{max_id}.avro"

    retval = {
      max_id: max_id,
      path: filename
    }

    begin
      json_file = "#{filename}.json"
      File.open(json_file, 'w') do |f|
        interface.data(table, min_id, max_id).each do |datum|
          Yajl::Encoder.encode(datum, f)
          f.write "\n"
        end
      end

      cmd = "java -jar #{AVRO_TOOLS_PATH} fromjson --codec snappy --schema '#{schema}' #{json_file} > #{filename}"
      `#{cmd}`

      `rm #{json_file}`
    rescue
      retval[:error] = $!.to_s
    end

    retval
  end
end

