package Mojolicious::Plugin::CHI;
use Mojo::Base 'Mojolicious::Plugin';
use CHI;

our $VERSION = '0.06';

# Register Plugin
sub register {
  my ($plugin, $mojo, $param) = @_;

  # Load parameter from Config file
  if (my $config_param = $mojo->config('CHI')) {
    $param = { %$config_param, %$param };
  };

  # Hash of cache handles
  my $caches = {};

  # Support namespaces
  my $ns = delete $param->{namespaces} // 1;

  # Loop through all caches
  foreach my $name (keys %$param) {
    my $cache_param = $param->{$name};

    # Already exists
    if (exists $caches->{$name}) {
      $mojo->log->warn("Multiple attempts to establish cache '$name'");
      next;
    };

    # Set namespace
    if ($ns) {
      $cache_param->{namespace} //= $name unless $name eq 'default';
    };

    # Get CHI handle
    my $cache = CHI->new( %$cache_param );

    # No succesful creation
    unless ($cache) {
      $mojo->log->warn("Unable to create cache handle '$name'");
    };

    # Store CHI handle
    $caches->{$name} = $cache;
  };


  # Add 'chi' helper
  $mojo->helper(
    chi => sub {
      my $c = shift;
      my $name = shift // 'default';

      my $cache = $caches->{$name};

      # Cache unknown
      $mojo->log->warn("Unknown cache handle '$name'") unless $cache;

      # Return cache
      return $cache;
    });
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::CHI - Use CHI caches in Mojolicious


=head1 SYNOPSIS

  # Mojolicious
  $app->plugin(CHI => {
    MyCache => {
      driver     => 'FastMmap',
      root_dir   => '/cache',
      cache_size => '20m'
    }
  });

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

=head2 register

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
    },
    namespaces => 1
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

All cache handles are qualified L<CHI> namespaces.
You can omit this mapping by passing a C<namespaces>
parameter with a C<false> value.

The handles have to be unique, i.e.
you can't have multiple different C<default> caches in mounted
applications using L<Mojolicious::Plugin::Mount>.

All parameters can be set either on registration or
as part of the configuration file with the key C<CHI>.


=head1 HELPERS

=head2 chi

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


=head1 CONTRIBUTORS

L<Boris Däppen|https://github.com/borisdaeppen>

L<reneeb|https://github.com/reneeb>


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-CHI


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
