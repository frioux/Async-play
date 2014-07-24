#!/usr/bin/env perl

use 5.20.0;
use warnings;

use experimental 'signatures';

use IO::Async::Loop;
use IO::Async::Timer::Periodic;

my $loop = IO::Async::Loop->new;

my $server = $loop->listen(
   host => '0.0.0.0',
   socktype => 'stream',
   service => 9933,

   on_stream => sub ($stream) {
      $stream->configure(
         on_read => sub ($self, $buffref, $eof) {
            $self->write($$buffref);
            $$buffref = '';
            0
         },
      );

      $stream->add_child(
         IO::Async::Timer::Periodic->new(
            interval => 5,
            on_tick => sub ($self) { $self->parent->write("ping!\n") },
         )->start
      );
      $loop->add( $stream );
   },

   on_resolve_error => sub { die "Cannot resolve - $_[1]\n"; },
   on_listen_error => sub { die "Cannot listen - $_[1]\n"; },

   on_listen => sub ($s) {
      warn "listening on: " . $s->sockhost . ':' . $s->sockport . "\n";
   },

);

$loop->run;
