#!/bin/bash

FILE_WORDNET_IS_A='imagenet-files/wordnet.is_a.txt'

# Input:
#   child
# Output:
#   child, parent, ...

child="$1"
isa="$2"
egrep "${child}$" $FILE_WORDNET_IS_A |
awk ' { print $1 }' |
xargs echo $child
