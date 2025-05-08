#!/bin/bash
# source sustainml environment
source "/sustainml/install/setup.bash"

if [[ ${SUSTAINML_NODE} == "desktop" ]]; then
    /sustainml/build/sustainml/sustainml
else
    cd /sustainml/src/sustainml_lib/sustainml_modules/sustainml_modules/
    if [[ ${SUSTAINML_NODE} == "back_end" ]]; then
        python3 sustainml-wp5/backend_node.py
    elif [[ ${SUSTAINML_NODE} == "front_end" ]]; then
        python3 sustainml-wp4/frontend_node.py
    elif [[ ${SUSTAINML_NODE} == "app_requirements" ]]; then
        python3 sustainml-wp1/app_requirements_node.py
    elif [[ ${SUSTAINML_NODE} == "carbon_tracker" ]]; then
        python3 sustainml-wp3/carbon_footprint_node.py
    elif [[ ${SUSTAINML_NODE} == "hw_constraints" ]]; then
        python3 sustainml-wp2/hw_constraints_node.py
    elif [[ ${SUSTAINML_NODE} == "hw_resources" ]]; then
        python3 sustainml-wp2/hw_resources_provider_node.py
    elif [[ ${SUSTAINML_NODE} == "ml_model_metadata" ]]; then
        python3 sustainml-wp1/ml_model_metadata_node.py
    elif [[ ${SUSTAINML_NODE} == "ml_model" ]]; then
        python3 sustainml-wp1/ml_model_provider_node.py
    else
        echo "Unknown node: ${SUSTAINML_NODE}"
        exit 1
    fi
fi

