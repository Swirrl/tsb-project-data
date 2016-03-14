## Innovate UK Linked Data.

Rails app to provide access to information about TSB Projects as Linked Open Data.

[![Build Status](https://travis-ci.org/Swirrl/tsb-project-data.svg?branch=master)](https://travis-ci.org/Swirrl/tsb-project-data)

Note that this project is several years old (hence old versions of some prerequisities and libraries), but some work has recently been done to resurrect it for a demonstration.

### Getting started

* `bundle`
* Edit the environment config (e.g. development.rb) to point the endpoints to a running [Fuseki](https://jena.apache.org/documentation/serving_data/) instance.
* Download and install v0.90 of [Elastic Search](http://www.elasticsearch.org).
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

#### Reindexing Elasticsearch

If you already have all the data in your triple store, you can just reindex the projects with:
`rake search:reimport_projects`

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

This [unofficial Docker image](https://hub.docker.com/r/tianjiang/elasticsearch-0.9/) is available for ElasticSearch 0.9 (which works with the `tire` gem used in this project).

e.g. Start elasticsearch, exposed on port 9200, mounting a volume for the data and logs.

`docker run -d -p 9200:9200 --name elasticsearch -v <dir on host>:/data tianjiang/elasticsearch-0.9`

#### Fuseki

[Download and run Fuseki 1.x](https://jena.apache.org/documentation/serving_data/) on port 3030.

Here's an example config file

```
@prefix tdb:     <http://jena.hpl.hp.com/2008/tdb#> .
@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix ja:      <http://jena.hpl.hp.com/2005/11/Assembler#> .
@prefix fuseki:  <http://jena.apache.org/fuseki#> .
[] rdf:type fuseki:Server ;
   # Services available.  Only explicitly listed services are configured.
   #  If there is a service description not linked from this list, it is ignored.
   ja:context [ ja:cxtName "arq:queryTimeout" ;  ja:cxtValue "10000,20000" ] ;
   fuseki:services (
     <#service-innovateuk>
   ) .

[] ja:loadClass "com.hp.hpl.jena.tdb.TDB" .
tdb:DatasetTDB  rdfs:subClassOf  ja:RDFDataset .
tdb:GraphTDB    rdfs:subClassOf  ja:Model .
<#service-innovateuk>  rdf:type fuseki:Service ;
    fuseki:name              "innovateuk" ;       # http://host:port/tsb
    fuseki:serviceQuery      "sparql" ;           # SPARQL query service
    fuseki:serviceUpdate     "update" ;           # SPARQL update service
    fuseki:serviceReadWriteGraphStore "data" ;    # SPARQL Graph store protocol (read and write)
    fuseki:dataset           <#dataset-innovateuk> ;
    .
 <#dataset-innovateuk> rdf:type      tdb:DatasetTDB ;
     tdb:location "/var/lib/pmd-data/fuseki/innovateuk" ;
     tdb:unionDefaultGraph true ;
     .
```

#### The PublishMyData app:

This will serve the app on port 8080, which you can proxy to with Nginx or similar.

`export HOSTIP=<eth0 ip>`
`docker run -d -p 127.0.0.1:8080:8080  -v <dir on host>:/pmd/public --add-host docker-host:$HOSTIP --name pmd swirrl/innovateuk-projects:build_xx`



