
image_path="$1"
represent_synset="$2"
reference_synsets_file="$3"

# 先頭以外のsynsets
equivalent_synsets="`                       \
  egrep "^${represent_synset}"            | \
  head -n1                                | \
  awk '{ for (i=2; i<=NF; i++) print $i; }' \
  `"
egrep "^${represent_synset}"
