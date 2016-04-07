default: setup docs

docs:
	docco --css docs.css --layout parallel src/*

setup: elasticsearch-0.90.3 elasticsearch.plist

elasticsearch-0.90.3:
	curl --remote-name http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.3.zip
	unzip elasticsearch-0.90.3.zip
	rm elasticsearch-0.90.3.zip

elasticsearch.plist:
	sed 's|CURRENT_DIRECTORY|$(PWD)|' < elasticsearch.plist.template > elasticsearch.plist
	launchctl load elasticsearch.plist

clean:
	launchctl unload elasticsearch.plist
	rm elasticsearch.plist
	rm -rf elasticsearch-*
