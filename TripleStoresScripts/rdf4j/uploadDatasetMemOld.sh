#!/bin/bash

VM_IP="yourServerIp"

curl -X PUT -H "Content-Type: text/turtle" --data-binary @aas_production_env_100100100_old_random_optimized.ttl http://$VM_IP:8080/rdf4j-server/repositories/mem-old/rdf-graphs/dataset
