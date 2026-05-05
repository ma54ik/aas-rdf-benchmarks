#!/bin/bash

# --- KONFIGURATION ---
VM_IP="yourServerIp"
REPS=("lmdb-old" "lmdb-new")
TARGET_URI="urn:aas:DriveUnitAAS:DU-1004"
LATENCY_RESULTS="results.csv"

ITERATIONS=1000

# URL dictionary indexed by store name (use VM_IP variable)
declare -A URLS
URLS[rdf4j]="http://$VM_IP:8080/rdf4j-server/repositories/"
URLS[virtuoso]="http://$VM_IP:8890/sparql/"
URLS[qlever_old]="http://$VM_IP:7001/api/"
URLS[qlever_new]="http://$VM_IP:7002/api/"

echo "store, representation, query, mean_ms +/- ci95_ms, sd_ms, " > "$LATENCY_RESULTS"

# --- QUERY DEFINITIONEN ---
Q1Old="
PREFIX aas:      <https://admin-shell.io/aas/3/0/>
PREFIX aas-aas:  <https://admin-shell.io/aas/3/0/AssetAdministrationShell/>
PREFIX aas-id:   <https://admin-shell.io/aas/3/0/Identifiable/>
PREFIX aas-ref:  <https://admin-shell.io/aas/3/0/Reference/>
PREFIX aas-key:  <https://admin-shell.io/aas/3/0/Key/>
PREFIX aas-sm:   <https://admin-shell.io/aas/3/0/Submodel/>
PREFIX aas-refb: <https://admin-shell.io/aas/3/0/Referable/>
PREFIX aas-prop: <https://admin-shell.io/aas/3/0/Property/>

SELECT ?propertyName ?propertyValue ?valueType
WHERE {
  ?aas a aas:AssetAdministrationShell ;
       aas-id:id \"$TARGET_URI\" .

  ?aas aas-aas:submodels / aas-ref:keys / aas-key:value ?smId .

  ?sm aas-id:id ?smId .
  ?sm aas-sm:submodelElements / (!<:>)* ?prop .

  ?prop a aas:Property ;
        aas-refb:idShort ?propertyName ;
        aas-prop:value ?propertyValue .

  OPTIONAL { ?prop aas-prop:valueType ?valueType }
}
"

Q1New="
prefix aas: <https://admin-shell.io/aas/3/>

SELECT ?propertyName ?propertyValue ?valueType
WHERE {
  <$TARGET_URI> a aas:AssetAdministrationShell ;
       aas:submodel/aas:submodelElement/(!<:>*) ?prop .

  ?prop a aas:Property ;
        aas:idShort ?propertyName ;
        aas:value ?propertyValue .

  OPTIONAL { ?prop aas:valueType ?valueType }
}"

Q1NewQlever="
prefix aas: <https://admin-shell.io/aas/3/>

SELECT ?propertyName ?propertyValue ?valueType
WHERE {
  <https://company.com/aas/$TARGET_URI> a aas:AssetAdministrationShell ;
       aas:submodel/aas:submodelElement/(!<:>*) ?prop .

  ?prop a aas:Property ;
        aas:idShort ?propertyName ;
        aas:value ?propertyValue .

  OPTIONAL { ?prop aas:valueType ?valueType }
}"

Q2Old="
PREFIX aas:      <https://admin-shell.io/aas/3/0/>
PREFIX aas-aas:  <https://admin-shell.io/aas/3/0/AssetAdministrationShell/>
PREFIX aas-ai:   <https://admin-shell.io/aas/3/0/AssetInformation/>
PREFIX aas-said: <https://admin-shell.io/aas/3/0/SpecificAssetId/>
PREFIX aas-ref:  <https://admin-shell.io/aas/3/0/Reference/>
PREFIX aas-key:  <https://admin-shell.io/aas/3/0/Key/>
PREFIX aas-id:   <https://admin-shell.io/aas/3/0/Identifiable/>
PREFIX aas-sm:   <https://admin-shell.io/aas/3/0/Submodel/>
PREFIX aas-refb: <https://admin-shell.io/aas/3/0/Referable/>
PREFIX aas-prop: <https://admin-shell.io/aas/3/0/Property/>
PREFIX xsd:      <http://www.w3.org/2001/XMLSchema#>

SELECT (COUNT(*) AS ?c)
WHERE {
  ?aas a aas:AssetAdministrationShell ;
       aas-aas:assetInformation / aas-ai:specificAssetIds [
         aas-said:value \"DriveUnit\"
       ] ;
       aas-aas:submodels / aas-ref:keys / aas-key:value ?smId .

  ?sm aas-id:id ?smId ;
      aas-sm:submodelElements / (!<:>) ?p1 .

  ?p1 aas-refb:idShort \"ratedPower\" ;
      aas-prop:value ?v1 .

  FILTER (xsd:double(?v1) > 15.0)
}
"

Q2New="
prefix aas: <https://admin-shell.io/aas/3/>
select (count(*) as ?c) { 
  ?aas a aas:AssetAdministrationShell ;
    aas:assetInformation/aas:specificAssetId [ aas:value \"DriveUnit\" ] ;
    aas:submodel/aas:submodelElement/(!<:>) ?p1 .
    ?p1 aas:idShort \"ratedPower\" ; aas:value ?v1 . 
    filter (?v1 > 15.0)
}
"

Q3Old="
PREFIX aas:     <https://admin-shell.io/aas/3/0/>
PREFIX aas-aas: <https://admin-shell.io/aas/3/0/AssetAdministrationShell/>
PREFIX aas-ref: <https://admin-shell.io/aas/3/0/Reference/>
PREFIX aas-key: <https://admin-shell.io/aas/3/0/Key/>
PREFIX aas-id:  <https://admin-shell.io/aas/3/0/Identifiable/>
PREFIX aas-sm:  <https://admin-shell.io/aas/3/0/Submodel/>
PREFIX aas-smc: <https://admin-shell.io/aas/3/0/SubmodelElementCollection/>
PREFIX aas-rel: <https://admin-shell.io/aas/3/0/RelationshipElement/>
PREFIX aas-prop:<https://admin-shell.io/aas/3/0/Property/>
PREFIX aas-refb:<https://admin-shell.io/aas/3/0/Referable/>
PREFIX xsd:     <http://www.w3.org/2001/XMLSchema#>

SELECT ?lineAAS (COUNT(DISTINCT ?compAAS) AS ?numDrives) (AVG(xsd:double(?val)) AS ?avgPower)
WHERE {
  ?lineAAS a aas:AssetAdministrationShell ;
           aas-aas:submodels / aas-ref:keys / aas-key:value ?smId .

  ?sm a aas:Submodel ;
      aas-id:id ?smId ;
      aas-sm:submodelElements ?rel .

  ?rel a aas:RelationshipElement ;
       aas-rel:second / aas-ref:keys / aas-key:value ?compId .

  ?compAAS a aas:AssetAdministrationShell ;
           aas-id:id ?compId ;
           aas-aas:submodels / aas-ref:keys / aas-key:value ?compSmId .

  ?compSm a aas:Submodel ;
          aas-id:id ?compSmId .

  ?compSm (aas-sm:submodelElements | aas-smc:value)+ ?prop .

  ?prop aas-refb:idShort \"ratedPower\" ;
        aas-prop:value ?val .
}
GROUP BY ?lineAAS
"

Q3OldCount="
PREFIX aas:     <https://admin-shell.io/aas/3/0/>
PREFIX aas-aas: <https://admin-shell.io/aas/3/0/AssetAdministrationShell/>
PREFIX aas-ref: <https://admin-shell.io/aas/3/0/Reference/>
PREFIX aas-key: <https://admin-shell.io/aas/3/0/Key/>
PREFIX aas-id:  <https://admin-shell.io/aas/3/0/Identifiable/>
PREFIX aas-sm:  <https://admin-shell.io/aas/3/0/Submodel/>
PREFIX aas-smc: <https://admin-shell.io/aas/3/0/SubmodelElementCollection/>
PREFIX aas-rel: <https://admin-shell.io/aas/3/0/RelationshipElement/>
PREFIX aas-prop:<https://admin-shell.io/aas/3/0/Property/>
PREFIX aas-refb:<https://admin-shell.io/aas/3/0/Referable/>
PREFIX xsd:     <http://www.w3.org/2001/XMLSchema#>

SELECT (COUNT(*) AS ?numLines)
WHERE {
  {
    SELECT ?lineAAS (COUNT(DISTINCT ?compAAS) AS ?numDrives) (AVG(xsd:double(?val)) AS ?avgPower)
    WHERE {
      ?lineAAS a aas:AssetAdministrationShell ;
               aas-aas:submodels / aas-ref:keys / aas-key:value ?smId .
    
      ?sm a aas:Submodel ;
          aas-id:id ?smId ;
          aas-sm:submodelElements ?rel .

      ?rel a aas:RelationshipElement ;
           aas-rel:second / aas-ref:keys / aas-key:value ?compId .

      ?compAAS a aas:AssetAdministrationShell ;
               aas-id:id ?compId ;
               aas-aas:submodels / aas-ref:keys / aas-key:value ?compSmId .

      ?compSm a aas:Submodel ;
              aas-id:id ?compSmId .

      ?compSm (aas-sm:submodelElements | aas-smc:value)+ ?prop .

      ?prop aas-refb:idShort \"ratedPower\" ;
            aas-prop:value ?val .
    }
    GROUP BY ?lineAAS
  }
}
"

Q3New="
PREFIX aas: <https://admin-shell.io/aas/3/>
PREFIX ns2: <https://admin-shell.io/aas/3/extended/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT ?lineAAS (COUNT(DISTINCT ?compAAS) AS ?numDrives) (AVG(xsd:double(?val)) AS ?avgPower)
WHERE {
  ?lineAAS a aas:AssetAdministrationShell ;
           aas:submodel / aas:submodelElement ?rel .
  ?rel a aas:RelationshipElement ;
       aas:second / ns2:resolvesTo ?compAAS .
  ?compAAS aas:submodel / aas:submodelElement / (aas:value)* ?prop .
  ?prop aas:idShort \"ratedPower\" ;
        aas:value ?val .
}
GROUP BY ?lineAAS
"

Q3NewCount="
PREFIX aas: <https://admin-shell.io/aas/3/>
PREFIX ns2: <https://admin-shell.io/aas/3/extended/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT (COUNT(*) AS ?numLines)
WHERE {
  {
    SELECT ?lineAAS (COUNT(DISTINCT ?compAAS) AS ?numDrives) (AVG(xsd:double(?val)) AS ?avgPower)
    WHERE {
      ?lineAAS a aas:AssetAdministrationShell ;
               aas:submodel / aas:submodelElement ?rel .
      ?rel a aas:RelationshipElement ;
           aas:second / ns2:resolvesTo ?compAAS .
      ?compAAS aas:submodel / aas:submodelElement / (aas:value)* ?prop .
      ?prop aas:idShort \"ratedPower\" ;
            aas:value ?val .
    }
    GROUP BY ?lineAAS
  }
}
"

measure_remote() {
  local store=$1 rep=$2 q_name=$3 query=$4
  local total=0 sum_sq_diff=0 
  local base_url endpoint ms_value elapsed avg ci variance stddev
  local extra_args=()
  local -a measurements=()

  if [[ "$store" == "virtuoso" ]]; then
    extra_args=(--data-urlencode "default-graph-uri=http://example.org/$rep")
  fi

  if [[ ! "$store" =~ ^(rdf4j|virtuoso|qlever)$ ]]; then
    echo "Unknown store: $store"; exit 1
  fi

  # determine base URL for the store (qlever has old/new variants)
  case "$store" in
    rdf4j|virtuoso)
      base_url="${URLS[$store]}"
      endpoint="${base_url}${rep}"
      ;;
    qlever)
      if [[ "$rep" =~ old ]]; then
        base_url="${URLS[qlever_old]}"
      else
        base_url="${URLS[qlever_new]}"
      fi
      endpoint="${base_url}"
      ;;
  esac

  echo "Testing query $q_name on $store ($rep) with $ITERATIONS iterations ..."
  echo "Endpoint: $endpoint"

  curl -X POST "$endpoint" \
      -H "Accept: text/csv" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -H "Cache-Control: no-cache, no-store" \
      "${extra_args[@]}" \
      --data-urlencode "query=$query"
  echo ""

  # Warm-up
  elapsed=$(curl -s -o /dev/null -w "%{time_total}" -X POST "$endpoint" \
      -H "Accept: text/csv" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -H "Cache-Control: no-cache, no-store" \
      "${extra_args[@]}" \
      --data-urlencode "query=$query")
  echo "Warmup: $(echo "1000 * $elapsed" | bc -l)"

  for ((i=0; i<ITERATIONS; i++)); do
    elapsed=$(curl -s -o /dev/null -w "%{time_total}" -X POST "$endpoint" \
      -H "Accept: text/csv" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -H "Cache-Control: no-cache, no-store" \
      "${extra_args[@]}" \
      --data-urlencode "query=$query")
    ms_value=$(echo "1000 * $elapsed" | bc -l)
    measurements+=("$ms_value")
    total=$(echo "$total + $ms_value" | bc -l)
  done

  local avg_raw
  avg_raw=$(echo "$total / $ITERATIONS" | bc -l)

  # calculate variance
  for val in "${measurements[@]}"; do
    sum_sq_diff=$(echo "$sum_sq_diff + ($val - $avg_raw)^2" | bc -l)
  done
  variance=$(echo "$sum_sq_diff / ($ITERATIONS - 1)" | bc -l)

  # calculate standard deviation
  local stddev_raw
  stddev_raw=$(echo "sqrt($variance)" | bc -l)

  # calculate confidence interval
  # ci = avg +- z * stddev / sqrt(n)
  # Margin of Error for 95% CI (z=1.96)
  local ci_raw
  ci_raw=$(echo "1.96 * $stddev_raw / sqrt($ITERATIONS)" | bc -l)

  avg=$(printf %.3f "$avg_raw")
  stddev=$(printf %.3f "$stddev_raw")
  ci=$(printf %.3f "$ci_raw")

  echo "$store, $rep, $q_name, $avg +/- $ci, $stddev" >> "$LATENCY_RESULTS"
  echo -e "\n" 
}

echo ""
echo ""
echo "----- Q1 running ... -----"
echo ""
echo ""

# Q1
measure_remote "rdf4j" "mem-old" "Q1_Props" "$Q1Old"
measure_remote "rdf4j" "mem-new" "Q1_Props" "$Q1New"
measure_remote "virtuoso" "old" "Q1_Props" "$Q1Old"
measure_remote "virtuoso" "new" "Q1_Props" "$Q1New"
measure_remote "qlever" "old" "Q1_Props" "$Q1Old"
measure_remote "qlever" "new" "Q1_Props" "$Q1NewQlever"

echo -e "\n" >> "$LATENCY_RESULTS"

echo ""
echo ""
echo "----- Q2 running ... -----"
echo ""
echo ""

# Q2
measure_remote "rdf4j" "mem-old" "Q2_Range" "$Q2Old"
measure_remote "rdf4j" "mem-new" "Q2_Range" "$Q2New"
measure_remote "virtuoso" "old" "Q2_Range" "$Q2Old"
measure_remote "virtuoso" "new" "Q2_Range" "$Q2New"
measure_remote "qlever" "old" "Q2_Range" "$Q2Old"
measure_remote "qlever" "new" "Q2_Range" "$Q2New"

echo -e "\n" >> "$LATENCY_RESULTS"

echo ""
echo ""
echo "----- Q3 running ... -----"
echo ""
echo ""

# Q3
measure_remote "rdf4j" "mem-old" "Q3_Aggregation" "$Q3Old"
# measure_remote "rdf4j" "mem-old" "Q3_Aggregation" "$Q3OldCount"
measure_remote "rdf4j" "mem-new" "Q3_Aggregation" "$Q3New"
# measure_remote "rdf4j" "mem-new" "Q3_Aggregation" "$Q3NewCount"
measure_remote "virtuoso" "old" "Q3_Aggregation" "$Q3Old"
# measure_remote "virtuoso" "old" "Q3_Aggregation" "$Q3OldCount"
measure_remote "virtuoso" "new" "Q3_Aggregation" "$Q3New"
# measure_remote "virtuoso" "new" "Q3_Aggregation" "$Q3NewCount"
measure_remote "qlever" "old" "Q3_Aggregation" "$Q3Old"
# measure_remote "qlever" "old" "Q3_Aggregation" "$Q3OldCount"
measure_remote "qlever" "new" "Q3_Aggregation" "$Q3New"
# measure_remote "qlever" "new" "Q3_Aggregation" "$Q3NewCount"

echo "Done - results are in $LATENCY_RESULTS"
