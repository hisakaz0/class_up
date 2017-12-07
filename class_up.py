#!/usr/bin/env python

import sys
import os
import argparse
from pprint import pprint as pp
import pickle

_DEFAULT_MAX_INT = -10000
_DEFAULT_MIN_INT =  10000


def main():

    parser = argparse.ArgumentParser(description='Hypernyming synsets in Imagenet')
    parser.add_argument('isa', help='Path to isa file')
    parser.add_argument('synsets', help='Path to synsets file')
    parser.add_argument('train', help='Path to train pairs file')
    parser.add_argument('val', help='Path to val pairs file')
    parser.add_argument('--out', default='res',
            help='Path to output directory')
    parser.add_argument('--num_synsets', default=100, type=int,
            help='Number of synsets of subset')
    parser.add_argument('--use_pickle', default=False, action='store_true',
            help='Flag to enable loading pickle objects')
    args = parser.parse_args()

    ## init
    print("Loading isa file: {}".format(args.isa))
    isa = Isa(args.isa)
    print("Loading synsets file: {}".format(args.synsets))
    synsets = Synsets(args.synsets)

    num_synsets = args.num_synsets

    pickle_synsets = os.path.join(args.out, 'synsets.pickle.py')
    if os.path.isfile(pickle_synsets) and args.use_pickle:
        print("Loading pickle of synsets.")
        with open(pickle_synsets, 'rb') as f:
            synsets = pickle.load(f)
    else:
        synsets.make_subset(isa, num_synsets)
        print("Writing subset synsets.")
        synsets.write_subset(os.path.join(args.out, 'synsets.txt'))
        print("Dumping pickle of synsets.")
        with open(pickle_synsets, 'wb') as f:
            pickle.dump(synsets, f)

    def pairs_process(pairs, synsets, out):
        basename = os.path.basename(pairs).split('.')[0]

        print("Loading val pairs file: {}".format(pairs))
        pairs = Pairs(pairs)

        pickle_pairs = os.path.join(out, "{}-pairs.pickle.py".format(basename))
        if os.path.isfile(pickle_pairs) and args.use_pickle:
            print("Loading pickle of {} pairs".format(basename))
            with open(pickle_pairs, 'rb') as f:
                pairs = pickle.load(f)
        else:
            print("Making list of subset labels.")
            pairs.add_subset_label(synsets.subset)
            print("Making list of reference_labels.")
            pairs.add_reference_labels(synsets.last_level_subset)
            print("Dumping list of pairs")
            with open(pickle_pairs, 'wb') as f:
                pickle.dump(pairs, f)

        print("Writing subset pairs")
        pairs.write_subset(os.path.join(out, basename + "-subset.txt"))
        print("Writing reference pairs")
        pairs.write_reference(os.path.join(out, basename + "-reference.txt"))

    # pairs_process(args.train, synsets, args.out)
    pairs_process(args.val, synsets, args.out)



class Isa:

    def __init__(self, path):
        self.isa = [l.split() for l in open(path).read().strip().split('\n')]

    def search_parents(self, synset):
        parents = []
        for parent, child in self.isa:
            if (synset == child):
                parents.append(parent)
        return sorted(parents)

    def search_children(self, synset):
        children = []
        for parent, child in self.isa:
            if (synset == parent):
                children.append(child)
        return sorted(children)


class Synset:

    def __init__(self, synset, label):
        self.org_synset = synset
        self.org_label = label
        self.parents = []
        self.line = []
        self.index = 0
        self.line.append(synset)
        self.current_label = -1
        self.common_root_synsets = []

    @property
    def current_synset(self):
        return self.line[self.index]

    def add_parents(self, parents):
        if (len(parents) > 0):
            self.parents.append(parents)
            self.line.append(parents[0])

    def go_parent(self):
        if (self.index < len(self.line)-1):
            self.index += 1
            return self.index
        return -1 # parent is root(末端)

    def go_child(self):
        if (self.index > 0):
            self.index -= 1
            return self.index
        return -1 # child is leaf(末端)

    @property
    def common_root_labels(self):
        labels = []
        labels.append(self.org_label)
        for synset in self.common_root_synsets:
            labels.append(synset.org_label)
        return labels

    def has_org_label(self, label):
        if (self.org_label == label):
            return True
        return False

    def has_common_root_labels(self, label):
        if (self.has_org_label(label)):
            return True
        elif (self._has_reference_root_labels(label)):
            return True
        return False

    def _has_reference_root_labels(self, label):
        for synset in self.common_root_synsets:
            if (synset.org_label == label):
                return True
        return False



class Synsets:

    def __init__(self, path):
        self.synsets = [Synset(s,i) for i,s in enumerate(open(path).read().strip().split('\n'))]
        self.subset = None

    def __len__(self):
        return len(set([l.current_synset for l in self.synsets]))

    def make_subset(self, isa, num_synsets=100):
        print("Making subset of synsets.")
        # 与えられたsynsetsから目標の数までHypernymingする
        level = 1
        multi_parents = {}
        def report_multi_parents(synsets):
            num_max = _DEFAULT_MAX_INT
            num_min = _DEFAULT_MIN_INT
            for synset in synsets:
                num_parents = len(synset.parents[-1])
                num_max = max(num_parents, num_max)
                num_min = min(num_parents, num_min)
            print("number of multi parents: {}".format(len(synsets)))
            print("max of multi_parents   : {}".format(num_max))
            print("min of multi_parents   : {}".format(num_min))

        while (len(self) >= num_synsets):
            print("Level: {} | Number of synsets: {}".format(
                level, len(self)))
            multi_parents[level] = []
            for synset in self.synsets:
                parents = isa.search_parents(synset.current_synset)
                if (len(parents) > 1):
                    multi_parents[level].append(synset)
                synset.add_parents(parents)
                synset.go_parent()
            report_multi_parents(multi_parents[level])
            level += 1

        # 上のwhileで目標数以下になるため、深さを1つだけ戻す
        for synset in self.synsets:
            synset.go_child()

        assert len(self) >= num_synsets, "Error: make subset function is broken."

        # 重複を調べる。もとのsynsetがHypernymingしたときに到達するsynset
        # を持つ、同階層レベルのsynsetの有無を調べる。

        # 同じrootを持つ共通のsynsetを調べ、最初にヒットしたsynsetを
        # 代表としてlast_level_subsetに追加する
        last_level_subset, current_synsets = [], []
        def search_repre_synset(current, synsets):
            for synset in synsets:
                if (current == synset.current_synset):
                    return synset
        for synset in self.synsets:
            current = synset.current_synset
            if (current not in current_synsets):
                last_level_subset.append(synset) # as repre_synset
                current_synsets.append(current)
            else:
                # 代表synsetでないならば、代表を検索
                # 代表synsetに、common_root_synsetsとしてsynsetを追加する
                repre_synset = search_repre_synset(current, last_level_subset)
                repre_synset.common_root_synsets.append(synset)
        self.last_level_subset = last_level_subset


        subset = []
        # last_level_subsetから所望の数だけsynsetを取り出し、
        # それらをsubsetとして確定する. 取り出した順にlabel(=index)をつける
        for index, synset in enumerate(last_level_subset):
            if (index >= num_synsets):
                break
            synset.current_label = index
            subset.append(synset)

        assert len(subset) == num_synsets, "Error: mismatch len(subset) and num_synsets"

        self.subset = subset

    def write_subset(self, out):
        """Writing synsets of subset. The synset is original synset instead of
        hypernymed one."""
        with open(out, 'w') as f:
            for synset in self.subset:
                # 画像の元ラベルと対応させるためにoriginalのsynsetを書き込む
                f.write("{}\n".format(synset.org_synset))

class Pair:

    def __init__(self, image_path, label):
        self.image_path = image_path
        self.org_label = label
        self.reference_labels = []
        self.subset_label = None

class Pairs:

    def __init__(self, path):
        self.pairs = []
        for line in open(path).read().strip().split('\n'):
            image_path, label = line.split()
            self.pairs.append(Pair(image_path, int(label)))

    def add_reference_labels(self, last_level_subset):
        def get_reference_labels(label, last_level_subset):
            for synset in last_level_subset:
                if (synset.has_common_root_labels(label)):
                    return synset.common_root_labels
        for pair in self.pairs:
            pair.reference_labels = get_reference_labels(
                    pair.org_label, last_level_subset)

    def add_subset_label(self, subset):
        """Adding the label which is in subset. Search key is label of pair.
        If the target label is founed, take the label from subset of synsets.
        Else, return `None'"""
        def get_subset_label(label, subset):
            for synset in subset:
                if (synset.has_org_label(label)):
                    return synset.current_label
            return None
        for pair in self.pairs:
            pair.subset_label = get_subset_label(pair.org_label, subset)

    def write_reference(self, out):
        with open(out, 'w') as f:
            for pair in self.pairs:
                f.write("{} ".format(pair.image_path))
                str_labels = [str(l) for l in pair.reference_labels]
                f.write("{}\n".format(" ".join(str_labels)))

    def write_subset(self, out):
        """Writing pairs related with subset synsets only.
        If a label of the pair is not found, the pair line is not write."""
        with open(out, 'w') as f:
            for pair in self.pairs:
                if pair.subset_label is not None:
                    f.write("{} {}\n".format(pair.image_path, pair.subset_label))

if __name__ == "__main__":
    main()
