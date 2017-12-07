#!/usr/bin/env bash
# set -x
# usage: class_up.py [-h] [--out OUT] [--num_synsets NUM_SYNSETS]
#                    [--load_synsets] [--dump_synsets DUMP_SYNSETS]
#                    isa synsets train val
# class_up.py: error: the following arguments are required: isa, synsets, train, val

out='res/tmp'
mkdir -p $out

time ./class_up.py \
  --out $out \
  imagenet-files/wordnet.is_a.txt \
  imagenet-files/synsets.txt \
  imagenet-files/train.txt \
  imagenet-files/val.txt
# 
# cat $out/val-reference.txt   |
# sed -e "s@^[A-Z0-9a-z._]*@@" | # 先頭の画像パスを削除
# awk '{ print NF }'           | # 1画像のラベル数だけを表示
# sort -n                      |
# uniq -c                      | # n個のラベル数をもつ画像の数をカウント
# awk '{ print $2,$1 }'        | # 列の入れ替え
# cat > $out/hist1.txt
# 
# cat > $out/hist1.plt << EOF
# set terminal "svg"
# set output "$out/hist1.svg"
# plot "$out/hist1.txt" using 2
# EOF
# chmod 755 $out/hist1.plt
# gnuplot $out/hist1.plt
