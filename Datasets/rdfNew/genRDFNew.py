import json
from json.decoder import JSONDecodeError

import random
random.seed(10)

from rdflib import Graph, Namespace, URIRef, Literal, RDF, RDFS

import py_aas_rdf
from py_aas_rdf.models.submodel import Submodel
from py_aas_rdf.models.concept_description import ConceptDescription
from py_aas_rdf.models.asset_administraion_shell import AssetAdministrationShell
import zipfile
import tempfile
from pathlib import Path
import json
from rdflib import Graph

import aas_core3.xmlization as aas_xmlization
import aas_core3.jsonization as aas_jsonization

from py_aas_rdf.models.environment import Environment
import os
import io



def bind_namespaces(graph):
    graph.bind("aas-identifiable", Namespace("https://admin-shell.io/aas/3/0/Identifiable/"))
    graph.bind("aas-assetadministrationshell", Namespace("https://admin-shell.io/aas/3/0/AssetAdministrationShell/"))
    graph.bind("aas-assetinformation", Namespace("https://admin-shell.io/aas/3/0/AssetInformation/"))
    graph.bind("aas-assetkind", Namespace("https://admin-shell.io/aas/3/0/AssetKind/"))
    graph.bind("aas-conceptdescription", Namespace("https://admin-shell.io/aas/3/0/ConceptDescription/"))
    graph.bind("aas-dataspecificationiec61360", Namespace("https://admin-shell.io/aas/3/0/DataSpecificationIec61360/"))
    graph.bind("aas-datatypedefxsd", Namespace("https://admin-shell.io/aas/3/0/DataTypeDefXsd/"))
    graph.bind("aas-keytypes", Namespace("https://admin-shell.io/aas/3/0/KeyTypes/"))
    graph.bind("aas-submodel", Namespace("https://admin-shell.io/aas/3/0/Submodel/"))
    graph.bind("aas-specificassetid", Namespace("https://admin-shell.io/aas/3/0/SpecificAssetId/"))
    graph.bind("aas-reference", Namespace("https://admin-shell.io/aas/3/0/Reference/"))
    graph.bind("aas-referencetypes", Namespace("https://admin-shell.io/aas/3/0/ReferenceTypes/"))
    graph.bind("aas-resource", Namespace("https://admin-shell.io/aas/3/0/Resource/"))
    graph.bind("aas-modellingkind", Namespace("https://admin-shell.io/aas/3/0/ModellingKind/"))
    graph.bind("aas-haskind", Namespace("https://admin-shell.io/aas/3/0/HasKind/"))
    graph.bind("aas-hassemantics", Namespace("https://admin-shell.io/aas/3/0/HasSemantics/"))
    graph.bind("aas-referable", Namespace("https://admin-shell.io/aas/3/0/Referable/"))
    graph.bind("aas-property", Namespace("https://admin-shell.io/aas/3/0/Property/"))
    graph.bind("aas-key", Namespace("https://admin-shell.io/aas/3/0/Key/"))
    graph.bind("aas-abstractlangstring", Namespace("https://admin-shell.io/aas/3/0/AbstractLangString/"))
    graph.bind("aas-qualifier", Namespace("https://admin-shell.io/aas/3/0/Qualifier/"))
    graph.bind("aas-administrativeinformation", Namespace("https://admin-shell.io/aas/3/0/AdministrativeInformation/"))
    graph.bind("aas-submodelelementcollection", Namespace("https://admin-shell.io/aas/3/0/SubmodelElementCollection/"))
    graph.bind("aas-qualifierkind", Namespace("https://admin-shell.io/aas/3/0/QualifierKind/"))
    graph.bind("aas-environment", Namespace("https://admin-shell.io/aas/3/0/Environment/"))
    graph.bind("aas-shortcuts", Namespace("https://admin-shell.io/aas/3/0/Shortcuts/"))
    graph.bind("aas", Namespace("https://admin-shell.io/aas/3/0/"))
    graph.bind("aas-multilanguageproperty", Namespace("https://admin-shell.io/aas/3/0/MultiLanguageProperty/"))

# import the json dataset
file_path = '../../dataset.json'

try:
	with open(file_path, 'r') as inputFile:
	    input_string = inputFile.read()
except FileNotFoundError:
    print(f"Fehler: Die Datei '{file_path}' wurde nicht gefunden.")
    sys.exit(1)

def execute_logic():
    AAS = Namespace("https://admin-shell.io/aas/3/0/")
    # input_string = data_area.value
    # Identify the input format (JSON/RDF)
    try:
        input_as_json = json.loads(input_string)
        # validate

        # Identify the model type
        if input_as_json.get('modelType') == "Submodel":
            graph, node = Submodel(**input_as_json).to_rdf()
        elif input_as_json.get('modelType') == "ConceptDescription":
            graph, node = ConceptDescription(**input_as_json).to_rdf()
        elif input_as_json.get('modelType') == "AssetAdministrationShell":
            graph, node = AssetAdministrationShell(**input_as_json).to_rdf()
        else:
            print("Processing Environment takes some time, wait!!!")
            graph = Graph()
            graph, node = Environment(**input_as_json).to_rdf(graph)

        graph = graph.skolemize(authority="https://company.com/aas/",basepath="/.well-known/genid/aas/")
        # Bind the custom namespace with a prefix, otherwise, the output will look weird
        # This is one of the problems of AAS/RDF !
        bind_namespaces(graph)


        output_string = graph.serialize(format="turtle_custom",base="https://company.com/aas/")
    except JSONDecodeError:
        g = Graph().parse(data=input_string, format='turtle')
        submodels_subjects = [subject for subject in g.subjects(predicate=RDF.type, object=AAS["Submodel"])]
        assetadministrationshell_subjects = [subject for subject in g.subjects(predicate=RDF.type, object=AAS["AssetAdministrationShell"])]
        conceptdescription_subjects = [subject for subject in g.subjects(predicate=RDF.type, object=AAS["ConceptDescription"])]
        output_string = f"# Found {len(submodels_subjects)} Submodel, {len(assetadministrationshell_subjects)} AssetAdministrationShell , {len(conceptdescription_subjects)} ConceptDescription \n"
        for subject in assetadministrationshell_subjects:
            output_string += AssetAdministrationShell.from_rdf(g,subject).model_dump_json(exclude_none=True,indent=2)
            output_string += "\n"
        for subject in submodels_subjects:
            output_string += Submodel.from_rdf(g,subject).model_dump_json(exclude_none=True,indent=2)
            output_string += "\n"
        for subject in conceptdescription_subjects:
            output_string += ConceptDescription.from_rdf(g,subject).model_dump_json(exclude_none=True,indent=2)
            output_string += "\n"

    # save the string in output file
    with open('datasetNew.ttl', 'w') as output_file:
        output_file.write(output_string)

# execute logic function
execute_logic()

print(f"Finished!")
