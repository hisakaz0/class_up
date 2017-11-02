#!/bin/bash

cmd_get_child="./get_child.sh"

# Input:
#   level, dir, synset
# Output:
#   first synset

level="$1"
dir="$2"
synset="$3"

current_isa="$dir/isa.$level"
while [ $level -gt 0 ] ; do
  child=`$cmd_get_child $synset $current_isa`
  synset=$child
  level=$((level-1))
  current_isa="$dir/isa.$level"
done
echo $synset
