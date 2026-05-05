#!/bin/bash

# "old" Datensatz hochladen

curl -v -X POST \
  "http://10.102.240.241:8890/sparql-graph-crud-http?graph-uri=http://example.org/old" \
  -u "dba:benchpass" \
  -H "Content-Type: text/turtle" \
  -T aas_production_env_100100100_old_random_optimized.ttl

# "new" Datensatz hochladen

curl -v -X POST \
  "http://10.102.240.241:8890/sparql-graph-crud-http?graph-uri=http://example.org/new" \
  -u "dba:benchpass" \
  -H "Content-Type: text/turtle" \
  -T aas_production_env_100100100_new_20260330_random.ttl
