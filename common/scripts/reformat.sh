#!/bin/bash

set -e

generate_new_file_names() {
    for var in "$@"; do
        echo ${var} | tr ' ' '_' | tr '[:upper:]' '[:lower:]'
    done
}

run_main () {
    generate_new_file_names
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_main
fi
