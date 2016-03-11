## TSB Project Linked Data

Rails app to provide access to information about TSB Projects as Linked Open Data.

[![Build Status](https://travis-ci.org/Swirrl/tsb-project-data.svg?branch=master)](https://travis-ci.org/Swirrl/tsb-project-data)

### Getting started

* `bundle`
* Edit the environment config (e.g. development.rb) to point the endpoints to a running [Fuseki](https://jena.apache.org/documentation/serving_data/) instance.
* Download and install v0.90 of Elastic Search [How?](http://www.elasticsearch.org/guide/reference/setup/).
* `rails server`

#### Running the data loader
`REPLACE_SUPPORTING=true INPUT_FILENAME='datatest1000.xlsx' rake loader:complete_load`

This will:

* look for an excel file in the `/data/input-data` folder with the name in the `INPUT_FILENAME` env var
* replace the supporting data (if `REPLACE_SUPPORTING` is `true`)
* delete search index
* parse excel file and creates .nt dump,
* replace dataset data
* creates search index

See the other rake tasks for how to run these steps individually.

### Docker

There's a public docker repo here for the rails app:
https://hub.docker.com/r/swirrl/innovateuk-projects/

### Running in production.

Prerequisites:

#### Memcached

We recommend using the [official memcached Docker image](https://hub.docker.com/_/memcached/).

e.g. Start memcached with a max storage of 1024MB, and slab size of 10MB, and expose to the host on port 11211

`docker run -d -p 11211:11211 --name memcached -d memcached -m 512 -I 10m`

#### Elasticsearch

We recommend using the [official Elasticsearch Docker image](https://hub.docker.com/_/elasticsearch/)

e.g. Start elasticsearch, exposed on port 9200, mounting volumes for the data and logs.

`docker run -d -p 9200:9200 --name elasticsearch -v <ES data dir on host>:/usr/share/elasticsearch/data -v <ES logs dir on host>:/usr/share/elasticsearch/logs elasticsearch`

#### Fuseki

download and run fuseki on port 3030.

#### The PublishMyData app:
`export HOSTIP=<eth0 ip>`
`docker run -d -p 127.0.0.1:8080:8080 -v /var/lib/pmd-data/pmd-public:/pmd/public --add-host docker-host:$HOSTIP --name pmd swirrl/innovateuk-projects:build_xxx`

