class DbInterface
  def schema(table)
    raise "Return Avro JSON schema for #{table}"
  end

  def data(table)
    raise "Return Avro JSON data for #{table}"
  end
end

