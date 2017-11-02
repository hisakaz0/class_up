#!/bin/bash

# Input:
#   pairs_synsets, label, synset
# Output:
#   image_path, label

out="$1"
pairs_synsets="$2"
label="$3"
synset="$4"

egrep " ${synset}$" $pairs_synsets |
sed -e "s@ $synset@ $label@g" > "$out/synset.$label"
