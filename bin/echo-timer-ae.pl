#!/usr/bin/env perl

use 5.20.0;
use warnings;

use experimental 'signatures', 'postderef';

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

my $j = AnyEvent->condvar;
my @handles;
my %timers;

my $server = tcp_server undef, 9934, sub {
   my ($fh, $host, $port) = @_;

   my $hdl = AnyEvent::Handle->new(
      fh => $fh,
      on_eof => sub { warn "client connection $host:$port: eof\n"; delete $timers{shift @_} },
      on_read => sub ($hdl) {
         $hdl->push_write($hdl->rbuf);
         substr($hdl->{rbuf}, 0) = '';
      },
   );
   push @handles, $hdl;

   $timers{$hdl} = AnyEvent->timer(
      after    => 5,
      interval => 5,
      cb       => sub { $hdl->push_write("ping!\n") },
   );

}, sub ($fh, $thishost, $thisport) {
   warn "listening on $thishost:$thisport\n";
};

$j->recv;
