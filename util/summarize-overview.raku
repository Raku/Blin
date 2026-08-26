#!/usr/bin/env raku

my %counts;
for "output/overview".IO.lines {
    my ($module, $status) = .split(' – ');
    %counts{$status//''}++;
}

use JSON::Fast;
say to-json(%counts, :pretty, :sorted-keys);
