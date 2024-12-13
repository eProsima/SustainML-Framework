#!/bin/bash
# source sustainml environment
source "/sustainml/install/setup.bash"

if [[ ${node} == "desktop" ]]; then
    /sustainml/build/sustainml/sustainml
else
    cd /sustainml/src/sustainml_lib/sustainml_modules/sustainml_modules/
    if [[ ${node} == "back-end" ]]; then
        python3 sustainml-wp5/backend_node.py
    elif [[ ${node} == "front-end" ]]; then
        python3 sustainml-wp4/frontend_node.py
    elif [[ ${node} == "app_requirements" ]]; then
        python3 sustainml-wp1/app_requirements_node.py
    elif [[ ${node} == "carbon_tracker" ]]; then
        python3 sustainml-wp3/carbon_footprint_node.py
    elif [[ ${node} == "hw_constraints" ]]; then
        python3 sustainml-wp2/hw_constraints_node.py
    elif [[ ${node} == "hw_resources" ]]; then
        python3 sustainml-wp2/hw_resources_provider_node.py
    elif [[ ${node} == "ml_model_metadata" ]]; then
        python3 sustainml-wp1/ml_model_metadata_node.py
    elif [[ ${node} == "ml_model" ]]; then
        python3 sustainml-wp1/ml_model_provider_node.py
    else
        echo "Unknown node: ${node}"
        exit 1
    fi
fi

