#!/bin/bash

curl -v -X PUT -H "Content-Type: text/turtle" --data-binary @repoRdf4jMemOld.ttl http://10.102.240.241:8080/rdf4j-server/repositories/mem-old
