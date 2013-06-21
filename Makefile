sql2avro-*.gem: sql2avro.gemspec
	bundle exec gem build $<

vendor/avro-tools-1.7.4.jar:
	curl http://www.us.apache.org/dist/avro/avro-1.7.4/java/avro-tools-1.7.4.jar > vendor/$@

