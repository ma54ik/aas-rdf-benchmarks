import json
import random

def generate_aas_dataset(num_lines=1, drives_per_line=2, sensors_per_line=1):
    aas_list = []
    submodel_list = []
    
    # --- 1. Define Common Concept Descriptions ---
    concept_descriptions = [
        {"id": "urn:cd:lineConsistsOfComponent", "idShort": "LineConsistsOfComponent", "modelType": "ConceptDescription", "category": "RELATIONSHIP"},
        {"id": "urn:cd:ratedPower", "idShort": "RatedPower", "modelType": "ConceptDescription", "category": "PARAMETER"},
        {"id": "urn:cd:ratedSpeed", "idShort": "RatedSpeed", "modelType": "ConceptDescription", "category": "PARAMETER"},
        {"id": "urn:cd:operatingHours", "idShort": "OperatingHours", "modelType": "ConceptDescription", "category": "PARAMETER"},
        {"id": "urn:cd:minTemp", "idShort": "MinTemperature", "modelType": "ConceptDescription", "category": "PARAMETER"},
        {"id": "urn:cd:maxTemp", "idShort": "MaxTemperature", "modelType": "ConceptDescription", "category": "PARAMETER"}
    ]

    for l_idx in range(1, num_lines + 1):
        line_id = f"PL-{l_idx:03d}"
        line_aas_id = f"urn:aas:ProductionLineAAS:{line_id}"
        line_sm_id = f"urn:submodel:ProductionLine:Overview:{line_id}"
        
        # --- 2. Create Production Line AAS ---
        line_aas = {
            "id": line_aas_id,
            "idShort": f"ProdLineAAS_{line_id.replace('-','_')}",
            "modelType": "AssetAdministrationShell",
            "assetInformation": {
                "assetKind": "Instance",
                "globalAssetId": f"urn:asset:ProductionLine:{line_id}"
            },
            "submodels": [{"type": "ModelReference", "keys": [{"type": "Submodel", "value": line_sm_id}]}]
        }
        aas_list.append(line_aas)

        # --- 3. Create Production Line Overview Submodel ---
        line_sm_elements = [
            {"idShort": "lineName", "modelType": "Property", "valueType": "xs:string", "value": f"Assembly Line {l_idx}"},
            {"idShort": "lineStatus", "modelType": "Property", "valueType": "xs:string", "value": "RUNNING"}
        ]

        # --- 4. Generate Drive Units for this Line ---
        for d_idx in range(1, drives_per_line + 1):
            du_id = f"DU-{l_idx:01d}{d_idx:02d}"
            du_aas_id = f"urn:aas:DriveUnitAAS:{du_id}"
            du_tech_sm_id = f"urn:submodel:DriveUnit:TechnicalData:{du_id}"
            du_maint_sm_id = f"urn:submodel:DriveUnit:Maintenance:{du_id}"

            # --- RANDOM WERTE FÜR DRIVE UNITS ---
            # Power zwischen 5.5 und 45.0 kW
            rand_power = round(random.uniform(10.0, 20.0), 1)
            # Speed zwischen 900 und 3000 RPM (Schritte von 50 möglich durch Multiplikation)
            rand_speed = random.randint(10, 30) * 100 
            # Betriebsstunden zwischen 0 und 10.000
            rand_hours = round(random.uniform(0.0, 1000.0), 1)

            # DU AAS
            aas_list.append({
                "id": du_aas_id,
                "idShort": f"DriveUnitAAS_{du_id.replace('-','_')}",
                "modelType": "AssetAdministrationShell",
                "assetInformation": {
                    "assetKind": "Instance",
                    "globalAssetId": f"urn:asset:DriveUnit:{du_id}",
                    "specificAssetIds": [
                        {"name": "componentType", "value": "DriveUnit"},
                        {"name": "parentLine", "value": line_id}
                    ]
                },
                "submodels": [
                    {"type": "ModelReference", "keys": [{"type": "Submodel", "value": du_tech_sm_id}]},
                    {"type": "ModelReference", "keys": [{"type": "Submodel", "value": du_maint_sm_id}]}
                ]
            })

            # DU Technical Submodel
            submodel_list.append({
                "id": du_tech_sm_id, "idShort": f"TechnicalData_{du_id.replace('-','_')}",
                "modelType": "Submodel", "kind": "Instance", "category": "TECHNICAL_DATA",
                "submodelElements": [{
                    "idShort": "motorConfig", "modelType": "SubmodelElementCollection",
                    "value": [
                        {"idShort": "ratedPower", "modelType": "Property", "valueType": "xs:double", "value": str(rand_power), 
                         "semanticId": {"type": "ModelReference", "keys": [{"type": "ConceptDescription", "value": "urn:cd:ratedPower"}]}},
                        {"idShort": "ratedSpeed", "modelType": "Property", "valueType": "xs:integer", "value": str(rand_speed),
                         "semanticId": {"type": "ModelReference", "keys": [{"type": "ConceptDescription", "value": "urn:cd:ratedSpeed"}]}}
                    ]
                }]
            })

            # DU Maintenance Submodel
            submodel_list.append({
                "id": du_maint_sm_id, "idShort": f"Maintenance_{du_id.replace('-','_')}",
                "modelType": "Submodel", "kind": "Instance", "category": "MAINTENANCE",
                "submodelElements": [
                    {"idShort": "operatingHours", "modelType": "Property", "valueType": "xs:double", "value": str(rand_hours),
                     "semanticId": {"type": "ModelReference", "keys": [{"type": "ConceptDescription", "value": "urn:cd:operatingHours"}]}}
                ]
            })

            # Link to Line Overview
            line_sm_elements.append({
                "idShort": f"consistsOf_{du_id.replace('-','_')}",
                "modelType": "RelationshipElement",
                "semanticId": {"type": "ModelReference", "keys": [{"type": "ConceptDescription", "value": "urn:cd:lineConsistsOfComponent"}]},
                "first": {"type": "ModelReference", "keys": [{"type": "AssetAdministrationShell", "value": line_aas_id}]},
                "second": {"type": "ModelReference", "keys": [{"type": "AssetAdministrationShell", "value": du_aas_id}]}
            })

        # --- 5. Generate Sensors for this Line ---
        for s_idx in range(1, sensors_per_line + 1):
            sen_id = f"SEN-{l_idx:01d}{s_idx:02d}"
            sen_aas_id = f"urn:aas:SensorAAS:{sen_id}"
            sen_tech_sm_id = f"urn:submodel:Sensor:TechnicalData:{sen_id}"

            # --- RANDOM WERTE FÜR SENSOREN ---
            # Minimaler Bereich zwischen -50.0 und -10.0
            rand_min_temp = round(random.uniform(-50.0, -10.0), 1)
            # Maximalwert: 50.0 bis 150.0
            rand_max_temp = round(random.uniform(50.0, 150.0), 1)

            aas_list.append({
                "id": sen_aas_id, "idShort": f"SensorAAS_{sen_id.replace('-','_')}",
                "modelType": "AssetAdministrationShell",
                "assetInformation": {"assetKind": "Instance", "globalAssetId": f"urn:asset:Sensor:{sen_id}"},
                "submodels": [{"type": "ModelReference", "keys": [{"type": "Submodel", "value": sen_tech_sm_id}]}]
            })

            submodel_list.append({
                "id": sen_tech_sm_id, "idShort": f"TechnicalData_{sen_id.replace('-','_')}",
                "modelType": "Submodel", "kind": "Instance", "category": "TECHNICAL_DATA",
                "submodelElements": [{
                    "idShort": "measurementRange", "modelType": "SubmodelElementCollection",
                    "value": [
                        {"idShort": "rangeMin", "modelType": "Property", "valueType": "xs:double", "value": str(rand_min_temp),
                         "semanticId": {"type": "ModelReference", "keys": [{"type": "ConceptDescription", "value": "urn:cd:minTemp"}]}},
                        {"idShort": "rangeMax", "modelType": "Property", "valueType": "xs:double", "value": str(rand_max_temp),
                         "semanticId": {"type": "ModelReference", "keys": [{"type": "ConceptDescription", "value": "urn:cd:maxTemp"}]}}
                    ]
                }]
            })

            line_sm_elements.append({
                "idShort": f"consistsOf_{sen_id.replace('-','_')}",
                "modelType": "RelationshipElement",
                "semanticId": {"type": "ModelReference", "keys": [{"type": "ConceptDescription", "value": "urn:cd:lineConsistsOfComponent"}]},
                "first": {"type": "ModelReference", "keys": [{"type": "AssetAdministrationShell", "value": line_aas_id}]},
                "second": {"type": "ModelReference", "keys": [{"type": "AssetAdministrationShell", "value": sen_aas_id}]}
            })

        # Add the line's overview submodel to the master list
        submodel_list.append({
            "id": line_sm_id, "idShort": "LineOverview", "modelType": "Submodel", 
            "kind": "Instance", "category": "OPERATION", "submodelElements": line_sm_elements
        })

    # --- 6. Final Assemble ---
    full_aas_env = {
        "assetAdministrationShells": aas_list,
        "submodels": submodel_list,
        "conceptDescriptions": concept_descriptions
    }
    return full_aas_env

# Configuration
config = {
    "num_lines": 100,
    "drives_per_line": 100,
    "sensors_per_line": 100
}

dataset = generate_aas_dataset(**config)

# Save to file
with open("dataset.json", "w") as f:
    json.dump(dataset, f, indent=2)

print(f"Successfully generated {len(dataset['assetAdministrationShells'])} AAS entities with randomized values.")
