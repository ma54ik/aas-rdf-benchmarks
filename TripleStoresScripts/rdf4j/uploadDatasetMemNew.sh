#!/bin/bash

VM_IP="yourServerIp"

curl -X PUT -H "Content-Type: text/turtle" --data-binary @aas_production_env_100100100_new_20260330_random.ttl http://$VM_IP:8080/rdf4j-server/repositories/mem-new/rdf-graphs/dataset
