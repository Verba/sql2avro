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
  def Sql2Avro.avroize(database_config, table, min_id, max_rows_per_batch=nil, directory='/tmp')
    raise "Database interface not specified." if !database_config.has_key? 'adapter'
    raise "Database interface not supported: #{database_config['adapter']}" unless ['mysql', 'mysql2'].include? database_config['adapter']

    interface = MySql.new(database_config)

    schema = Yajl::Encoder.encode(interface.schema(table))
    max_id = interface.max_id(table)
    max_id_this_batch = if max_rows_per_batch.nil?
      max_id
    else
      [max_id, min_id + max_rows_per_batch].min
    end

    date, time, zone = Time.now.utc.to_s.split
    filename = "#{table}.#{date}T#{time}Z.#{min_id}.#{max_id_this_batch}.avro"

    retval = {
      max_id: max_id_this_batch,
      path: File.join(directory, filename)
    }

    prev_default_internal = Encoding.default_internal
    Encoding.default_internal = nil

    json_file = File.join(directory, "#{filename}.json")
    File.open(json_file, 'w') do |f|
      interface.data(table, min_id, max_id_this_batch) do |datum|
        Yajl::Encoder.encode(datum, f)
        f.write "\n"
      end
    end

    Encoding.default_internal = prev_default_internal

    cmd = "java -jar #{AVRO_TOOLS_PATH} fromjson --codec snappy --schema '#{schema}' #{json_file} > #{File.join(directory, filename)}"
    `#{cmd}`
    if !$?.success?
      raise "Error converting JSON to Avro.\n\nCommand: #{cmd}\nStatus: #{$?}"
    end

    `rm #{json_file}`
    if !$?.success?
      raise "Error deleting temporary JSON file #{json_file}"
    end

    retval
  end
end

