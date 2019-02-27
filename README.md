# DEPRECATED

## DO NOT USE

# sql2avro

sql2avro extracts data from a SQL database table then transforms it into an [https://avro.apache.org/](Avro) file with schema based on the database table's. The target use case is incremental loading of data from an SQL database into [https://hadoop.apache.org/](HDFS) for analysis via [https://hadoop.apache.org/](Hadoop).

## Installation

    gem install sql2avro

## Usage

    require 'sql2avro'

    config = {
      host:     "localhost",
      username: "myuser",
      password: "mypass",
      database: "somedatabase"
    }
    min_id = 0
    output = Sql2Avro.avroize(config, 'table', min_id)

    error_message = output[:error]
    if !error_message.nil?
      p error_message
    else
      p "Successfully saved rows [#{min_id}, #{output[:max_id]}] to #{output[:path]}."
    end

## Gotchas

On OSX, the version of Snappy baked into Avro tools 1.7.4 has
trouble with JVM 7, so temporarily switch to JVM 6 using

    $ export JAVA_HOME=`/usr/libexec/java_home -v '1.6*'`

For details, see [http://www.michael-noll.com/blog/2013/03/17/reading-and-writing-avro-files-from-the-command-line/#known-issues-of-snappy-with-jdk-7-on-mac-os-x](here).

## License

Copyright 2013 Verba, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this software except in compliance with the License.
You may obtain a copy of the License in LICENSE.txt in this repository,
copied from http://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

