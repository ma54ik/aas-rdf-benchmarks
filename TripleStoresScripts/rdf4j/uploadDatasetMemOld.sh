#!/bin/bash

curl -X PUT -H "Content-Type: text/turtle" --data-binary @aas_production_env_100100100_old_random_optimized.ttl http://10.102.240.241:8080/rdf4j-server/repositories/mem-old/rdf-graphs/dataset
