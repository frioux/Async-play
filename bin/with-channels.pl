#!/usr/bin/env perl

use 5.22.0;
use warnings;

use Time::HiRes 'tv_interval', 'gettimeofday';

use IO::Async::Loop::Epoll;
use IO::Async::Routine;
use IO::Async::Channel;

my $loop = IO::Async::Loop::Epoll->new;

my $start_ch = IO::Async::Channel->new;
my $ch = IO::Async::Channel->new;
my $r  = IO::Async::Routine->new(
   channels_in => [ $start_ch ],
   channels_out => [ $ch ],

   code => sub {
      $start_ch->recv;

      $ch->send( \0 ) while 1
   },

   on_finish => sub {
      say "The routine aborted early - $_[-1]";
      $loop->stop;
   },
);

$loop->add($r);

my $t0 = [gettimeofday];
my $int = 0;
$start_ch->send( \0 );
$ch->recv(
   on_recv => sub {
      $int++;
      if (tv_interval($t0) > 1) {
         $t0 = [gettimeofday];
         say "$int/s";
         $int = 0;
      }
   },
);

$loop->run;

