#!/bin/bash -ex

#-----------------------------------------------------------------------------
# Functions

function print_usage () {
cat << EOF 1>&2
  usage: $0 <pairs_file> <synsets_file> <output_directory>

  Generated files int <output_directory>:
      synsets_file: synsets list which has specifid number of synset.
      pairs_file: pairs which has image_path and new label related synsets_file.

  Paramenters:
      NUM_PARALLEL: Number of worker
      NUM_SYNSETS: Number of synsets
EOF
}

function print_stderr () {
  echo $* 1>&2
}


#-----------------------------------------------------------------------------
# Parameter
NUM_PARALLEL=32
NUM_SYNSETS=100


#------------------------------------------------------------------------------
# Sub commands
cmd_get_parent="./get_parent.sh"
cmd_get_leaf="./get_leaf.sh"
cmd_replace_label="./replace_label.sh"
cmd_replace_synset="./replace_synset.sh"


#-----------------------------------------------------------------------------
# Main Program
if [ -z "$3" ] ; then
  print_usage
  exit 1
fi

pairs="$1"
synsets="$2"
out="`basename $3`"
mkdir -p $out

## get hypernym, and remove duplicate,
## and repeat it until $len_synsets less than $NUM_SYNSETS
level=0
current_synsets="$synsets"
len_synsets=`cat $current_synsets | wc -l`
while [ $len_synsets -gt $NUM_SYNSETS ] ; do # childeren goes toward the root.
  level=$((level+1))
  print_stderr "level of hyppernym: $level"
  new_synsets="$out/synsets.$level"
  new_isa="$out/isa.$level"

  cat $current_synsets                  | # child
  xargs -P$NUM_PARALLEL -n1 \
    $cmd_get_parent                     | # child (,parent, ...)
  awk ' { if (NF==1) { print $1,$1 }
          else       { print $1,$2 } }' | # child, parent
  awk ' { print $2,$1 }'                | # parent, child
  sort > $new_isa                         # sort with parent

  cat $new_isa           | # parent, child
  awk ' { print $2,$1 }' | # child, parent(swap)
  uniq -f 1              | # remove duplicate of parent (ignore child column)
  awk ' { print $2 }' > $new_synsets # only parents

  current_synsets="$new_synsets"
  len_synsets=`cat $new_synsets | wc -l`
done

## get leaf(original synset)
print_stderr "creating new synsets"
level=$((level-1))
current_synsets="$out/synsets.$level"
head -n$NUM_SYNSETS $current_synsets | # synset
xargs -P$NUM_PARALLEL -n1 \
  $cmd_get_leaf $level $out          | # leaf synset(original synset)
sort > "$out/`basename $synsets`"

## choose line only matching the label in $pairs,
## and replace label with synset
print_stderr "replacing label"
cat $synsets                | # synset
awk ' BEGIN { i=0 }
      { print i,$1;
        i += 1 }'           | # index, synset
xargs -P$NUM_PARALLEL -n2 \
  $cmd_replace_label $pairs | # image_path, synset
sort > "$out/pairs_synsets.txt"

## replace synset with new label
print_stderr "replacing synset"
cat "$out/`basename $synsets`"                 | # synset
awk ' BEGIN { i=0 }
      { print i,$1;
        i += 1}'                               | # index, synset
xargs -P$NUM_PARALLEL -n2 \
  $cmd_replace_synset "$out/pairs_synsets.txt" | # image_path, label
sort > "$out/`basename $pairs`"

