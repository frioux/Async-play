#!/usr/bin/env perl

use 5.22.0;
use warnings;

use Time::HiRes 'tv_interval', 'gettimeofday';

my $t0 = [gettimeofday];
my $int = 0;
while (1) {
   $int++;
   if (tv_interval($t0) > 1) {
      $t0 = [gettimeofday];
      say "$int/s";
      $int = 0;
   }
}
