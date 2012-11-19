package Mojolicious::Plugin::CHI;
use Mojo::Base 'Mojolicious::Plugin';
use CHI;

our $VERSION = '0.02';

# Register Plugin
sub register {
  my ($plugin, $mojo, $param) = @_;

  # Load parameter from Config file
  if (my $config_param = $mojo->config('CHI')) {
    $param = { %$config_param, %$param };
  };

  # Hash of cache handles
  my $caches;

  # No databases attached
  unless ($mojo->can('chi_handles')) {
    $caches = {};
    $mojo->attr(
      chi_handles => sub {
	return $caches;
      });
  }

  # Use attached databases
  else {
    $caches = $mojo->chi_handles;
  };

  # Init caches (on fork)
  Mojo::IOLoop->timer(
    0 => sub {

      # Loop through all caches
      foreach my $name (keys %$param) {
	my $cache_param = $param->{$name};

	# Already exists
	next if exists $caches->{$name};

	# Get Database handle
	my $cache = CHI->new( %$cache_param );

	# No succesful creation
	unless ($cache) {
	  $mojo->log->warn("Unable to create cache handle '$name'");
	};

	# Store database handle
	$caches->{$name} = $cache;
      };
    }
  );


  # Add 'chi' helper
  $mojo->helper(
    chi => sub {
      my $c = shift;
      my $name = shift // 'default';
      my $cache = $caches->{$name};

      # Database unknown
      $mojo->log->warn("Unknown cache handle '$name'") unless $cache;

      # Return cache
      return $cache;
    });
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::CHI - Use CHI caches within Mojolicious


=head1 SYNOPSIS

  # Mojolicious
  $app->plugin(CHI => {
    MyCache => {
      driver     => 'FastMmap',
      root_dir   => '/cache',
      cache_size => '20m'
    }
  );

  # Mojolicious::Lite
  plugin 'CHI' => {
    default => {
      driver => 'Memory',
      global => 1
    }
  };

  # In Controllers:
  $c->chi('MyCache')->set(my_key => 'This is my value');
  print $c->chi('MyCache')->get('my_key');

  # Using the default cache
  $c->chi->set(from_memory => 'With love!');
  print $c->chi->get('from_memory');


=head1 DESCRIPTION

L<Mojolicious::Plugin::CHI> is a simple plugin to work with
L<CHI> caches within Mojolicious.


=head1 METHODS

=head2 C<register>

  # Mojolicious
  $app->plugin(CHI => {
    MyCache => {
      driver     => 'FastMmap',
      root_dir   => '/cache',
      cache_size => '20m'
    },
    default => {
      driver => 'Memory',
      global => 1
    }
  });

  # Mojolicious::Lite
  plugin 'CHI' => {
    default => { driver => 'Memory', global => 1 }
  };

  # Or in your config file
  {
    CHI => {
      default => {
        driver => 'Memory',
        global => 1
      }
    }
  }

Called when registering the plugin.
On creation, the plugin accepts a hash of cache names
associated with L<CHI> objects.
All parameters can be set either on registration or
as part of the configuration file with the key C<CHI>.


=head1 HELPERS

=head2 C<chi>

  # In Controllers:
  $c->chi('MyCache')->set(my_key => 'This is my value', '10 min');
  print $c->chi('MyCache')->get('my_key');
  print $c->chi->get('from_default_cache');

Returns a L<CHI> handle if registered.
Accepts the name of the registered cache.
If no cache handle name is given, a cache handle name
C<default> is assumed.


=head1 DEPENDENCIES

L<Mojolicious>,
L<CHI>.

B<Note:> L<CHI> has a lot of dependencies. It is
thus not recommended to use this plugin in a CGI
environment.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-CHI


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Nils Diewald.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
