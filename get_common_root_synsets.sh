#!/bin/bash

synset="$1"
synsets="$2"

egrep "^${synset}" $synsets     | # synset, root
head -n1                        | # ほけん
awk '{ print $2 }'              | # root
xargs -I{} egrep "{}$" $synsets | # synset, root
awk '{ print $1 }'              | # synset
xargs echo $synset                # synset(candidated), synset, ...
