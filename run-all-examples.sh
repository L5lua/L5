#!/bin/bash
# Run all the L5 examples in examples/, one by one
for exampleDir in examples/*; do
    love $exampleDir
    read -n 1 -p "Press Enter (Return) to continue or q to quit: " response
    case $response in
        [qQ])
            echo
            exit 0
            ;;
    esac
done
