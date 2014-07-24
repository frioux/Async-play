#!/usr/bin/env perl

use 5.20.0;
use warnings;

use experimental 'signatures';

use POE qw(Wheel::ListenAccept Wheel::ReadWrite);

POE::Session->create(
   inline_states => {

      _start => sub {
         $_[HEAP]{server} = POE::Wheel::ListenAccept->new(
            Handle => IO::Socket::INET->new(
               LocalPort => 9935,
               Listen    => 5,
            ),
            AcceptEvent => "on_client_accept",
            ErrorEvent  => "on_server_error",
         );
         warn "listening on: 0.0.0.0:9935\n";
      },

      on_client_accept => sub {
         my $client_socket = $_[ARG0];
         my $io_wheel      = POE::Wheel::ReadWrite->new(
            Handle     => $client_socket,
            InputEvent => "on_client_input",
            ErrorEvent => "on_client_error",
         );
         warn "client connected\n";
         my $wheel_id = $io_wheel->ID;
         $_[KERNEL]->alarm( ping => time() + 5, $wheel_id);
         $_[HEAP]{client}{$wheel_id} = $io_wheel;
      },

      ping => sub {
         my $wheel_id = $_[ARG0];
         $_[HEAP]{client}{$wheel_id}->put('ping!');
         $_[KERNEL]->alarm( ping => time() + 5, $wheel_id);
      },

      on_server_error => sub {
         my ($operation, $errnum, $errstr) = @_[ARG0, ARG1, ARG2];
         warn "Server $operation error $errnum: $errstr\n";
         delete $_[HEAP]{server};
      },

      on_client_input => sub {
         my ($input, $wheel_id) = @_[ARG0, ARG1];
         $_[HEAP]{client}{$wheel_id}->put($input);
      },

      on_client_error => sub {
         my $wheel_id = $_[ARG3];
         delete $_[HEAP]{client}{$wheel_id};
         warn "client (probably) disconnected\n";
      },
   }
);

POE::Kernel->run;
