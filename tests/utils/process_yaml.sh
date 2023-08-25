#!/usr/bin/bash

run_python_yaml () {
    python3 -c "import yaml; y=open('$1').read(); print(yaml.safe_load(y)['$2'])"
}