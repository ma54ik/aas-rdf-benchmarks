#!/bin/bash

VM_IP="yourServerIp"

curl -v -X PUT -H "Content-Type: text/turtle" --data-binary @repoRdf4jMemNew.ttl http://$VM_IP:8080/rdf4j-server/repositories/mem-new
