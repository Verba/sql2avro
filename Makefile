vendor/avro-tools-1.7.4.jar:
	curl http://www.us.apache.org/dist/avro/avro-1.7.4/java/avro-tools-1.7.4.jar > vendor/$@

sql2avro-0.1.0.gem: sql2avro.gemspec
	bundle exec gem build $<

