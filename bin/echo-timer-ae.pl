#!/usr/bin/env perl

use 5.20.0;
use warnings;

use experimental 'signatures';

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::Loop;
use Scalar::Util 'refaddr';

my %handles;

my $server = tcp_server undef, 9934, sub ($fh, $host, $port) {
   my $hdl = AnyEvent::Handle->new(
      fh => $fh,
      on_eof => \&disconnect,
      on_error => \&disconnect,
      on_read => sub ($hdl) {
         $hdl->push_write($hdl->rbuf);
         substr($hdl->{rbuf}, 0) = '';
      },
   );
   $handles{refaddr $hdl} = $hdl;
   $hdl->{timer} = AnyEvent->timer(
      after    => 5,
      interval => 5,
      cb       => sub { $hdl->push_write("ping!\n") },
   )
}, sub ($fh, $thishost, $thisport) {
   warn "listening on $thishost:$thisport\n";
};

AnyEvent::Loop::run;

sub disconnect ($hdl, @) {
   warn "client disconnected\n";
   delete $handles{refaddr $hdl}
}
