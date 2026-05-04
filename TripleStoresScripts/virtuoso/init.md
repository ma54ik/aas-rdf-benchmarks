# "old" Datensatz laden

docker exec -it <container_name> isql 1111 dba benchpass exec="
  ld_dir('/usr/share/proj', 'old.ttl', 'http://example.org/old');
  rdf_loader_run();
"

# "new" Datensatz laden

docker exec -it <container_name> isql 1111 dba benchpass exec="
  ld_dir('/usr/share/proj', 'new.ttl', 'http://example.org/new');
  rdf_loader_run();
"

# check

docker exec -it <container_name> isql 1111 dba benchpass exec="
  SPARQL SELECT ?g (COUNT(*) AS ?cnt) WHERE { GRAPH ?g { ?s ?p ?o } } GROUP BY ?g;
"
