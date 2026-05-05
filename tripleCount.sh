#!/bin/bash

VM_IP="yourServerIp"

# Query
QUERY_TRIPLES="query=SELECT (COUNT(*) AS ?tripleCount) WHERE { ?s ?p ?o }"

# Function for POST endpoints
query_post() {
    local ENDPOINT="$1"
    local LABEL="$2"

    echo "=== $LABEL ==="
    echo "Endpoint: $ENDPOINT"

    TRIPLE_COUNT=$(curl -v -s -X POST "$ENDPOINT" \
        -H "Accept: text/csv" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "$QUERY_TRIPLES" 2>/dev/null | tr -d '\r' | tail -n 1)

    echo "Triples: $TRIPLE_COUNT"
    echo ""
}

# Function for Virtuoso (POST with default-graph-uri)
query_virtuoso() {
    local ENDPOINT="$1"
    local GRAPH="$2"
    local LABEL="$3"

    echo "=== $LABEL ==="
    echo "Endpoint: $ENDPOINT (graph: $GRAPH)"

    TRIPLE_COUNT=$(curl -v -s -X POST "$ENDPOINT" \
        -H "Accept: text/csv" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "default-graph-uri=$GRAPH" \
        --data-urlencode "$QUERY_TRIPLES" 2>/dev/null | tr -d '\r' | tail -n 1)

    echo "Triples: $TRIPLE_COUNT"
    echo ""
}

# --- RDF4J repositories ---
query_post "http://$VM_IP:8080/rdf4j-server/repositories/mem-new" "mem-new"
query_post "http://$VM_IP:8080/rdf4j-server/repositories/mem-old" "mem-old"
# query_post "http://$VM_IP:8080/rdf4j-server/repositories/native-new" "native-new"
# query_post "http://$VM_IP:8080/rdf4j-server/repositories/native-old" "native-old"
# query_post "http://$VM_IP:8080/rdf4j-server/repositories/lmdb-new" "lmdb-new"
# query_post "http://$VM_IP:8080/rdf4j-server/repositories/lmdb-old" "lmdb-old"

# --- Other SPARQL endpoints (POST) ---
query_post "http://$VM_IP:7002/api" "qlever-new"
query_post "http://$VM_IP:7001/api" "qlever-old"

# --- Virtuoso (POST with named graph) ---
query_virtuoso "http://$VM_IP:8890/sparql" "http://example.org/new" "virtuoso-new"
query_virtuoso "http://$VM_IP:8890/sparql" "http://example.org/old" "virtuoso-old"
