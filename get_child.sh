#!/bin/bash

# Input:
#   parent, isa
# Output:
#   child

parent="$1"
isa="$2"

egrep "^${parent}" $isa |
head -n1 |
awk '{ print $2 }'
