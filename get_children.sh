#!/bin/bash

# Input:
#   parent, isa
# Output:
#   child

parent="$1"
isa="$2"

egrep "^${parent}" $isa |
awk -v p="$parent" '{ print p,$2 }'
