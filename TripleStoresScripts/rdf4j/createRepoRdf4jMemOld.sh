#!/bin/bash

VM_IP="yourServerIp"

curl -v -X PUT -H "Content-Type: text/turtle" --data-binary @repoRdf4jMemOld.ttl http://$VM_IP:8080/rdf4j-server/repositories/mem-old
