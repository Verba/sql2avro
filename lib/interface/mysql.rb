require_relative './interface'
require 'open3'

class MySql < DbInterface
  MYSQL_BATCH_SEP = "\t"

  # config is a hash with this form (like ActiveRecord's):
  # {
  #   host:     "localhost",
  #   username: "myuser",
  #   password: "mypass",
  #   database: "somedatabase"
  # }
  #
  def initialize(config)
    @db_host = config['host']
    @db_name = config['database']
    @username = config['username']
    @password = config['password']
  end

  def schema(table)
    types = avro_types(table)

    schema = {
      type: "record",
      name: table,
      fields: []
    }

    types.each do |k,v|
      schema[:fields] << { name: k, type: ['null', v] }
    end

    schema
  end

  def max_id(table)
    header_seen = false
    query("SELECT MAX(id) FROM #{table}") do |line|
      unless header_seen
        header_seen = true
        next
      end

      return line.first.to_i
    end
  end

  def data(table, min_id, max_id)
    columns = nil
    rows = []

    types = avro_types(table)

    sql = """
      SELECT *
      FROM #{table}
      WHERE id >= #{min_id}
        AND id <= #{max_id}
    """
    query(sql) do |line|
      # Get header.
      if columns.nil?
        columns = line
        next
      end

      # Construct row mapping column names to values of appropriate type.
      row = (0...columns.length).each_with_object({}) do |i, h|
        colname = columns[i]
        value = line[i]

        # NOTE: all non-null type values are wrapped in a mapping from type to value,
        # because that's what the Avro spec requires; see:
        #  - http://avro.apache.org/docs/current/spec.html#json_encoding
        #  - http://mail-archives.apache.org/mod_mbox/avro-user/201304.mbox/%3CCD86687D.E892E%25scott@richrelevance.com%3E

        # Handle nulls.
        if value == "NULL"
          h[columns[i]] = nil
          next
        end

        # Perform any necessary typecasts.
        type = types[colname]
        h[colname] = case type
        when 'boolean'
          { type => value.to_i.zero? }
        when 'int','long'
          { type => value.to_i }
        when 'float','double'
          { type => value.to_f }
        when 'bytes'
          { type => value }
        when 'string'
          { type => value }
        else
          raise "Unsupported type: #{type}"
        end
      end

      rows << row
    end

    # TODO: stream this data out rather than return all in one batch.
    rows
  end

  def sql_schema(table)
    header_seen = false
    columns = {}

    query("DESCRIBE #{table}") do |line|
      if header_seen == false
        header_seen = true
        next
      end

      name, type = line[0], line[1]
      columns[name] = type
    end

    columns
  end

  def avro_types(table)
    mysql_types = sql_schema(table)

    types = {}
    mysql_types.each do |k,v|
      types[k] = MySql.avro_type(v)
    end

    types
  end

  def query(sql, &block)
    MySql.query(sql, @db_host, @db_name, @username, @password, &block)
  end

  def self.query(sql, db_host, db_name, username, password, &block)
    cmd = %{
      mysql \\
        --batch \\
        --execute="SET NAMES 'utf8'; #{sql}" \\
        --host #{db_host} \\
        --user #{username} \\
        --password=#{password} \\
        --quick \\
        #{db_name}
    }

    Open3.popen3(cmd) do |i, o, e|
      while (line = o.gets)
        block.call(line.chop.split(MYSQL_BATCH_SEP))
      end
    end
  end

  def self.avro_type(mysql_type)
    # Refer to https://github.com/apache/sqoop/blob/trunk/src/java/org/apache/sqoop/manager/ConnManager.java#L172.

    case mysql_type

    # See https://dev.mysql.com/doc/refman/5.0/en/numeric-type-overview.html
    when /tinyint\(1\)/, /bool/, /boolean/
      'boolean'
    when /tinyint/, /smallint/, /mediumint/, /integer/, /int/
      'int'
    when /bigint/, /serial/
      'long'
    when /decimal/, /dec/
      'string'
    when /float/
      'float'
    when /double/
      'double'
    when /varchar\(\d+\)/
      'string'

    # See https://dev.mysql.com/doc/refman/5.0/en/date-and-time-type-overview.html.
    when /date/, /datetime/, /time/, /timestamp/
      'string'
    when /year/
      'int'

    # See https://dev.mysql.com/doc/refman/5.0/en/string-type-overview.html.
    when /char/, /varchar/
      'string'
    when /binary/, /varbinary/
      'bytes'
    when /tinytext/, /text/, /longtext/
      'string'
    when /tinyblob/, /blob/, /longblob/
      'bytes'
    else
      raise "Unsupported MySQL data type: #{mysql_type}"
    end
  end

end

