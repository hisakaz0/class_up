#!/bin/bash

# Input:
#   synset, label, pairs
# Output:
#   image_path, synset

pairs="$1"
label="$2"
synset="$3"

egrep " ${label}$" $pairs |
sed -e "s@ $label@ $synset@g"
