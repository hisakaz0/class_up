#!/usr/bin/env bash
set -x

number_of_lines () {
  cat $1 |
  wc -l  |
  xargs echo "number of lines in `basename $1`: "
}

reset_file () {
  cat /dev/null > $1
}


out='res/005'
mkdir -p $out

## individual mode
#time ./class_up.py \
#  --out $out \
#  --write_individual \
#  imagenet-files/wordnet.is_a.txt \
#  imagenet-files/synsets.txt \
#  imagenet-files/train.txt \
#  imagenet-files/val.txt

time ./class_up.py \
  --out $out \
  imagenet-files/wordnet.is_a.txt \
  imagenet-files/synsets.txt \
  imagenet-files/train.txt \
  imagenet-files/val.txt

#cat $out/val-reference.txt   |
#sed -e "s@^[A-Z0-9a-z._]*@@" | # 先頭の画像パスを削除
#awk '{ print NF }'           | # 1画像のラベル数だけを表示
#sort -n                      |
#uniq -c                      | # n個のラベル数をもつ画像の数をカウント
#awk '{ print $2,$1 }'        | # 列の入れ替え
#cat > $out/hist1.txt
#
#reset_file $out/info.txt
#number_of_lines $out/synsets.txt         >> $out/info.txt
#number_of_lines $out/train-reference.txt >> $out/info.txt
#number_of_lines $out/train-subset.txt    >> $out/info.txt
#number_of_lines $out/val-subset.txt      >> $out/info.txt
#number_of_lines $out/val-reference.txt   >> $out/info.txt
#cat $out/val-reference.txt   |
#sed -e "s@^[A-Z0-9a-z._]*@@" |
#awk '{ print NF }'           |
#awk ' \
#  BEGIN { sum=0 } \
#  {sum+=$i} \
#  END{ print sum }'          |
#xargs echo 'sum(number of labels in val-reference.txt): ' >> $out/info.txt
#
#cat > $out/hist1.plt << EOF
#set terminal "svg"
#set output "$out/hist1.svg"
#plot "$out/hist1.txt" using 2
#EOF
#chmod 755 $out/hist1.plt
#gnuplot $out/hist1.plt

cp $0 $out
cp ./class_up.py $out
