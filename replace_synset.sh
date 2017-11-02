#!/bin/bash

# Input:
#   pairs_synsets, label, synset
# Output:
#   image_path, label

pairs_synsets="$1"
label="$2"
synset="$3"

egrep " ${synset}$" $pairs_synsets |
sed -e "s@ $synset@ $label@g"
