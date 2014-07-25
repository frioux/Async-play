#!/usr/bin/env perl

use 5.20.0;
use warnings;

use experimental 'signatures', 'postderef';

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::Loop;

my %handles;

my $server = tcp_server undef, 9934, sub {
   my ($fh, $host, $port) = @_;

   my $hdl = AnyEvent::Handle->new(
      fh => $fh,
      on_eof => \&disconnect,
      on_error => \&disconnect,
      on_read => sub ($hdl) {
         $hdl->push_write($hdl->rbuf);
         substr($hdl->{rbuf}, 0) = '';
      },
   );
   $handles{$hdl} = $hdl;
   $hdl->{timer} = AnyEvent->timer(
      after    => 5,
      interval => 5,
      cb       => sub { $hdl->push_write("ping!\n") },
   );

}, sub ($fh, $thishost, $thisport) {
   warn "listening on $thishost:$thisport\n";
};

AnyEvent::Loop::run;

sub disconnect ($hdl, @) {
   warn "client disconnected\n";
   delete $handles{$hdl}
}
