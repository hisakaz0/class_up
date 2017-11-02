#!/bin/bash

# Input:
#   out, pairs, synset, label
# Output:
#   image_path, synset

out="$1"
pairs="$2"
label="$3"
synset="$4"

egrep " ${label}$" $pairs |
sed -e "s@ $label@ $synset@g" > "$out/label.$label"
