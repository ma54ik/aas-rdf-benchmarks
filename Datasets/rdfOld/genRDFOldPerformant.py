import json
import os
import sys
import concurrent.futures
from json.decoder import JSONDecodeError
from rdflib import Graph, Namespace, RDF
from py_aas_rdf.models.submodel import Submodel
from py_aas_rdf.models.concept_description import ConceptDescription
from py_aas_rdf.models.asset_administraion_shell import AssetAdministrationShell

# --- Configuration ---
INPUT_FILE = '../..dataset.json'
OUTPUT_FILE = 'datasetOld.ttl'
MAX_WORKERS = os.cpu_count()  # Uses all available CPU cores

def bind_namespaces(graph):
    # (Your existing namespace bindings remain here)
    namespaces = {
        "aas-identifiable": "https://admin-shell.io/aas/3/0/Identifiable/",
        "aas-assetadministrationshell": "https://admin-shell.io/aas/3/0/AssetAdministrationShell/",
        "aas-assetinformation": "https://admin-shell.io/aas/3/0/AssetInformation/",
        "aas-assetkind": "https://admin-shell.io/aas/3/0/AssetKind/",
        "aas-conceptdescription": "https://admin-shell.io/aas/3/0/ConceptDescription/",
        "aas-dataspecificationiec61360": "https://admin-shell.io/aas/3/0/DataSpecificationIec61360/",
        "aas-datatypedefxsd": "https://admin-shell.io/aas/3/0/DataTypeDefXsd/",
        "aas-keytypes": "https://admin-shell.io/aas/3/0/KeyTypes/",
        "aas-submodel": "https://admin-shell.io/aas/3/0/Submodel/",
        "aas-specificassetid": "https://admin-shell.io/aas/3/0/SpecificAssetId/",
        "aas-reference": "https://admin-shell.io/aas/3/0/Reference/",
        "aas-referencetypes": "https://admin-shell.io/aas/3/0/ReferenceTypes/",
        "aas-resource": "https://admin-shell.io/aas/3/0/Resource/",
        "aas-modellingkind": "https://admin-shell.io/aas/3/0/ModellingKind/",
        "aas-haskind": "https://admin-shell.io/aas/3/0/HasKind/",
        "aas-hassemantics": "https://admin-shell.io/aas/3/0/HasSemantics/",
        "aas-referable": "https://admin-shell.io/aas/3/0/Referable/",
        "aas-property": "https://admin-shell.io/aas/3/0/Property/",
        "aas-key": "https://admin-shell.io/aas/3/0/Key/",
        "aas-abstractlangstring": "https://admin-shell.io/aas/3/0/AbstractLangString/",
        "aas-qualifier": "https://admin-shell.io/aas/3/0/Qualifier/",
        "aas-administrativeinformation": "https://admin-shell.io/aas/3/0/AdministrativeInformation/",
        "aas-submodelelementcollection": "https://admin-shell.io/aas/3/0/SubmodelElementCollection/",
        "aas-qualifierkind": "https://admin-shell.io/aas/3/0/QualifierKind/",
        "aas-environment": "https://admin-shell.io/aas/3/0/Environment/",
        "aas-shortcuts": "https://admin-shell.io/aas/3/0/Shortcuts/",
        "aas": "https://admin-shell.io/aas/3/0/",
        "aas-multilanguageproperty": "https://admin-shell.io/aas/3/0/MultiLanguageProperty/",
    }
    for prefix, uri in namespaces.items():
        graph.bind(prefix, Namespace(uri))

def convert_item_to_graph(item_type, data):
    """Worker function to convert a single item in a separate process."""
    try:
        temp_graph = Graph()
        if item_type == "Submodel":
            g, _ = Submodel(**data).to_rdf()
        elif item_type == "ConceptDescription":
            g, _ = ConceptDescription(**data).to_rdf()
        elif item_type == "AssetAdministrationShell":
            g, _ = AssetAdministrationShell(**data).to_rdf()
        return g
    except Exception as e:
        return None

def execute_logic():
    AAS = Namespace("https://admin-shell.io/aas/3/0/")
    
    try:
        with open(INPUT_FILE, 'r') as f:
            input_string = f.read()
        input_as_json = json.loads(input_string)
    except Exception as e:
        print(f"Error loading file: {e}")
        return

    main_graph = Graph()

    if input_as_json.get('modelType'):
        # Single object processing
        main_graph, _ = convert_item_to_graph(input_as_json.get('modelType'), input_as_json)
    else:
        # Batch processing Environment
        print(f"🚀 Processing environment using {MAX_WORKERS} workers...")
        
        # Prepare tasks
        tasks = []
        tasks.extend([("AssetAdministrationShell", x) for x in input_as_json.get('assetAdministrationShells', [])])
        tasks.extend([("Submodel", x) for x in input_as_json.get('submodels', [])])
        tasks.extend([("ConceptDescription", x) for x in input_as_json.get('conceptDescriptions', [])])

        # Execute in Parallel
        with concurrent.futures.ProcessPoolExecutor(max_workers=MAX_WORKERS) as executor:
            futures = [executor.submit(convert_item_to_graph, t, d) for t, d in tasks]
            
            for i, future in enumerate(concurrent.futures.as_completed(futures)):
                result_graph = future.result()
                if result_graph:
                    # CRITICAL FIX: In-place addition
                    main_graph += result_graph
                
                if i % 100 == 0:
                    print(f"✅ Processed {i}/{len(tasks)} items...")

    print("📝 Binding namespaces and serializing (this may take a minute)...")
    bind_namespaces(main_graph)
    
    # Use standard 'turtle' unless 'turtle_custom' is specifically required by your library version
    output_data = main_graph.serialize(format="turtle", base="https://company.com/aas/")
    
    with open(OUTPUT_FILE, 'w') as f:
        f.write(output_data)

if __name__ == "__main__":
    execute_logic()
    print(f"Finished! Saved to {OUTPUT_FILE}")
