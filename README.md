Tried to bake https://github.com/miyucy/snappy into Avro Ruby bindings,
but the compressed data was not readable by avro-tools jar; this was the
commit I based my work on:
https://github.com/apache/avro/commit/1e7a16eb1d624fd10b5b7676ade9a37b77234bb5.

NOTE: on OSX the version of Snappy baked into Avro tools 1.7.4 has
trouble with JVM 7, so temporarily switch to JVM 6 using

    export JAVA_HOME=`/usr/libexec/java_home -v '1.6*'`

Useful links:

  - http://www.michael-noll.com/blog/2013/03/17/reading-and-writing-avro-files-from-the-command-line/#known-issues-of-snappy-with-jdk-7-on-mac-os-x
  - http://www.igvita.com/2010/02/16/data-serialization-rpc-with-avro-ruby/
  - http://stackoverflow.com/a/13595102/1486325

