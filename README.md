# aas-rdf-benchmarks
Benchmarking SPARQL query performance of an improved AAS RDF representation across multiple triplestores.

## Introduction
This repository contains the scripts and datasets needed to evaluate the current RDF representation of the Asset Administration Shell (AAS) against an improved version, enabling reproduction of the benchmarks presented in the associated scientific paper.

## Prerequisites

- Docker >= 3.8
- Python >= 3.12.3
- pip >= 24.0
- Bash (tested under WSL 2)
- curl >= 8.19.0
- bc >= 1.08.2

## Replication Instructions
### 1. Clone the Repository

```bash
git clone .../aas-rdf-benchmarks.git
cd aas-rdf-benchmarks
```

### 2. Generate the Dataset (optional, used datasets are in the folder "Datasets")

Generate the json dataset:

```bash
cd Datasets/json
python3 genProdLineJsonRandom.py
cd ../..
```

Generate the old dataset:

```bash
cp Datasets/json/dataset.json Datasets/rdfOld
cd Datasets/rdfOld
sudo ./installMain.sh
source aas_prod_env/bin/activate
python3 genRDFOldPerformant.py
cd ../..
```

Generate the new dataset:

```bash
cp Datasets/json/dataset.json Datasets/rdfNew
cd Datasets/rdfNew
sudo ./installExperimental.sh
source aas_prod_env/bin/activate
python3 genRDFNew.py
cd ../..
```

Alternatively, extract the pre-built datasets directly into the upload directories:

```bash
tar -xf Datasets/rdfOld/oldRepresentation.tar.gz -C TripleStoresScripts/rdf4j/
tar -xf Datasets/rdfNew/newRepresentation.tar.gz -C TripleStoresScripts/rdf4j/

tar -xf Datasets/rdfOld/oldRepresentation.tar.gz -C TripleStoresScripts/virtuoso/
tar -xf Datasets/rdfNew/newRepresentation.tar.gz -C TripleStoresScripts/virtuoso/
```

### 3. Start the triple stores and load data

#### QLever – Build indices (before starting any containers)

> ⚠️ **Important:** QLever requires pre-built index files. Complete this step
> before running `docker compose up`.

##### Prepare directories on the server (start is in the benchmark directory)

```bash
mkdir -p data/qlever-old data/qlever-new
sudo chown -R 1000:1000 data/qlever-old data/qlever-new
```

##### Copy TTL-files

> ⚠️ **Important:** Adjust the commands according to your setup.

```bash
cp .../aas_production_env_100100100_old_random_optimized.ttl data/qlever-old/
cp .../aas_production_env_100100100_new_20260330_random.ttl data/qlever-new/
```

##### Configuration (identical for both)

```bash
cp TripleStoresScripts/qlever/settings.json data/qlever-old/
cp TripleStoresScripts/qlever/settings.json data/qlever-new/
```

##### Create index

```bash
# Old dataset

docker run --rm \
  -v ./data/qlever-old:/data \
  -w /data \
  --user "1000:1000" \
  --entrypoint qlever-index \
  adfreiburg/qlever \
  --index-basename=old \
  --kg-input-file=aas_production_env_100100100_old_random_optimized.ttl \
  --file-format=ttl \
  --settings-file=settings.json \
  --stxxl-memory=4G

# New dataset

docker run --rm \
  -v ./data/qlever-new:/data \
  -w /data \
  --user "1000:1000" \
  --entrypoint qlever-index \
  adfreiburg/qlever \
  --index-basename=new \
  --kg-input-file=aas_production_env_100100100_new_20260330_random.ttl \
  --file-format=ttl \
  --settings-file=settings.json \
  --stxxl-memory=4G
```

#### Start the containers

```bash
docker compose up -d 
```

#### RDF4J

Create repositories:
> ⚠️ **Important:** Before using any bash script, initialize the VM_IP variable with the IP address of the server hosting the triple stores.

```bash
cd TripleStoresScripts/rdf4j
./createRepoRdf4jMemOld.sh
./createRepoRdf4jMemNew.sh
```

Upload datasets:
> ⚠️ **Important:** This may take a couple of minutes.

```bash
./uploadDatasetMemOld.sh
./uploadDatasetMemNew.sh
cd ../..
```

#### Virtuoso

##### Copy the two datasets into the import directory on the server

```bash
cp .../aas_production_env_100100100_old_random_optimized.ttl ./data/import/
cp .../aas_production_env_100100100_new_20260330_random.ttl ./data/import/
```

##### Load the datasets into the triple store

> Note: The container name `triplestores-virtuoso-1` may differ depending on
> your Docker Compose project name. Adjust it if necessary (e.g. `virtuoso`).

```bash
docker exec -it triplestores-virtuoso-1 isql 1111 dba benchpass exec="
DELETE FROM DB.DBA.load_list;
ld_dir('/usr/share/proj', 'aas_production_env_100100100_old_random_optimized.ttl', 'http://example.org/old');
ld_dir('/usr/share/proj', 'aas_production_env_100100100_new_20260330_random.ttl', 'http://example.org/new');
rdf_loader_run();
checkpoint;
"
```

### 4. Verify

Verify the upload of the datasets via the triple count of each triple store.
Remember to update the script with the IP address of the server hosting the triple stores

```bash
./tripleCount.sh
```

The results should look like the following:
```
=== mem-new ===
Endpoint: http://<yourIp>:8080/rdf4j-server/repositories/mem-new
Triples: 2374037

=== mem-old ===
Endpoint: http://<yourIp>:8080/rdf4j-server/repositories/mem-old
Triples: 2003324

=== qlever-new ===
Endpoint: http://<yourIp>:7002/api
Triples: 2374037

=== qlever-old ===
Endpoint: http://<yourIp>:7001/api
Triples: 2003324

=== virtuoso-new ===
Endpoint: http://<yourIp>:8890/sparql (graph: http://example.org/new)
Triples: 2374037

=== virtuoso-old ===
Endpoint: http://<yourIp>:8890/sparql (graph: http://example.org/old)
Triples: 2003324
```

```bash
./blankNodeRatio.sh
```

The results should look like the following:
```
=== mem-new ===
Endpoint: http://<yourIp>:8080/rdf4j-server/repositories/mem-new
Blank Nodes:  0
Total Nodes:  608734
Ratio:        0

=== mem-old ===
Endpoint: http://<yourIp>:8080/rdf4j-server/repositories/mem-old
Blank Nodes:  300200
Total Nodes:  608731
Ratio:        .49315

=== qlever-new ===
Endpoint: http://<yourIp>:7002/api
Blank Nodes:  0
Total Nodes:  608734
Ratio:        0

=== qlever-old ===
Endpoint: http://<yourIp>:7001/api
Blank Nodes:  300200
Total Nodes:  608731
Ratio:        .49315

=== virtuoso-new ===
Endpoint: http://<yourIp>:8890/sparql (graph: http://example.org/new)
Blank Nodes:  0
Total Nodes:  608734
Ratio:        0

=== virtuoso-old ===
Endpoint: http://<yourIp>:8890/sparql (graph: http://example.org/old)
Blank Nodes:  300200
Total Nodes:  608731
Ratio:        .49315
```

### 5. Run the benchmark

```bash
./benchmarkWithStdDevAndCI.sh
```

## Environment

Results reported in resultsOfficial.csv were obtained on:

- Client: HP Firefly 14″ G10 Mobile Workstation, 16 GB RAM, WSL Arch Linux Shell
- Server: Linux Debian VM (Kernel 6.12.57-1) hosting the triple stores

## License

[MIT](LICENSE)
